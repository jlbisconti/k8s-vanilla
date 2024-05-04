# Introduccion 
El motivo de este deploy es el de realizar la prueba de conexion de mi cluster k8s contra el volumen ISCSI creado en mi NAS Iomega. Esta prueba busca cumplir con dos objetivos. En primer lugar aprender mas sobre k8s y en segundo lugar proporcionar una opcion de storage adicional.


## Escenario planteado
 Tenemos un cluster que consta de:

 - 1 nodo Master
- 3 nodos worker
- SO Ubuntu 22.04 Server 

El hipervisor utilizado para correr las VMs es VMware® Workstation 17 Pro 17.5.1 build-23298084. El flavor asignado a las VMs fue:
  - 4 CPU
  - 4 GB de RAM
  - 120 GB de disco
    
Vamos a cubrir la necesidad adicional de storage persistente para nuestros PODS con el protocolo ISCSI y realizaremos la creacion de un pod NGINX de prueba. La solucion que vamos a deployar en nuestro cluster sera openebs.

## Instalacion

 Como primer paso   vamos a crear el namespace openenbs
 ```bash
 kubectl create namespace openebs
```
Luego nos posisionaremos en el namspace creado:

 ```bash
 kubectl config set-context --current --namespace=openebs
```

Ahora agregaremos el repositorio helm correspondiente a openebs:
 ```bash
 helm repo add openebs https://openebs.github.io/charts
```
A continuacion instalamos el operador de openebs
 ```bash
helm install openebs openebs/openebs --namespace openebs
```
Verificamos la instalación del controlador:
 ```bash
kubectl get pods -n openebs
```

Esperamos a que todos los pods estén en estado "Running".
 ```text
jlb@master-01:~/iscsi$ kubectl get pods -n openebs
NAME                                           READY   STATUS   
openebs-localpv-provisioner-56d6489bbc-fdq5t   1/1     Running  
openebs-ndm-llmmj                              1/1     Running   
openebs-ndm-operator-5d7944c94d-vshpx          1/1     Running   
openebs-ndm-rxwkr                              1/1     Running   
openebs-ndm-sh7jj                              1/1     Running   
```

Ahora procedemos a crear el sorage class de openebs:
 ```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-iscsi
provisioner: openebs.io/provisioner-iscsi
parameters:
  openebs.io/storage-pool: default
 ```

verificamos la creacion del sc :
```bash
kubectl get sc
 ```
Deberiamos ver una salida como la siguiente:
 ```textplain
openebs-iscsi      openebs.io/provisioner-iscsi                    Delete          Immediate              false          
```

## Deploy de POD nginx con pv residente en el volumen ISCSI

El primer paso va a ser obtener informacion de nuestro target ISCSI con el siguiente comando:

 ```bash
sudo iscsiadm -m discovery -t st -p 10.10.150.2
```
Este comando nos traera la siguiente informacion:
 ```bash
10.10.150.2:3260,1 iqn.1992-04.com.emc:storage.Jorsat-NAS01.isci-nas
```
Como podemos ver tenemos:
 
`IP del target (NAS): 10.10.150.2`
`Puerto ISCSI: 3260`
`IQN: iqn.1992-04.com.emc:storage.Jorsat-NAS01.isci-nas`

Ahora procedemos a crear el pvc:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-iscsi
spec:
  storageClassName: openebs-iscsi
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```
 ```bash
 kubectl create -f pvc-iscsi.yaml
```

Y a continuacion creamos el pv:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: iscsi-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  iscsi:
    targetPortal: 10.10.150.2
    iqn: iqn.1992-04.com.emc:storage.Jorsat-NAS01.isci-nas
    lun: 0
    fsType: ext4
    readOnly: false
  persistentVolumeReclaimPolicy: Retain
  storageClassName: openebs-iscsi
```

```bash
kubectl create -f pv-iscsi.yaml
```

Verificamos el status de pv y pvc:

```bash
jlb@master-01:~$ kubectl get pv,pvc
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                 STORAGECLASS    VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/iscsi-pv                                   1Gi        RWO            Retain           Bound    microservicios/pvc-iscsi              
```
Como siguiente paso creamos y aplicamos el deployment de nuestro POD:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-iscsi
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-iscsi
  template:
    metadata:
      labels:
        app: nginx-iscsi
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: iscsi-pv
          mountPath: /usr/share/nginx/html
      volumes:
      - name: iscsi-pv
        persistentVolumeClaim:
          claimName:  pvc-iscsi
  storageClassName: openebs-iscsi
```

```bash
kubectl create -f deployment-nginx-iscsi.yaml          
```
Verficamos es status de nuestro POD:

```bash
jlb@master-01:~/iscsi$ kubectl get po
NAME                                   READY   STATUS    RESTARTS       
nginx-iscsi-58d445f4bf-xfh9l           1/1     Running   0               
```

Como ultimo paso ingresamos al POD:

```bash
kubectl exec -it nginx-iscsi-58d445f4bf-xfh9l /bin/bash
```
Veremos que en nuestro POD en el disco /dev/sdb esta montado el directorio de trabajo de NGINX:

```bash
root@nginx-iscsi-58d445f4bf-xfh9l:/# df -h
Filesystem                         Size  Used Avail Use% Mounted on
overlay                             58G  9.7G   46G  18% /
tmpfs                               64M     0   64M   0% /dev
/dev/mapper/ubuntu--vg-ubuntu--lv   58G  9.7G   46G  18% /etc/hosts
shm                                 64M     0   64M   0% /dev/shm
/dev/sdb                            49G   24K   49G   1% /usr/share/nginx/html

```
Asimismo podemos verdificar en nuestro nodo worker-03, el nodo que corre el pod la misma informacion:
```bash
jlb@worker-03:~$ lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0 63,9M  1 loop /snap/core20/2105
loop1                       7:1    0 63,9M  1 loop /snap/core20/2264
loop2                       7:2    0   87M  1 loop /snap/lxd/27037
loop3                       7:3    0 40,4M  1 loop /snap/snapd/20671
sda                         8:0    0  120G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  118G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0   59G  0 lvm  /var/lib/kubelet/pods/3c70279b-96ce-45bf-a1d5-b8c24153123b/volume-subpaths/config/openebs-ndm/0
                                                   /
sdb                         8:16   0   50G  0 disk /var/lib/kubelet/pods/19388735-aff2-49b0-b3f7-cbd2971ceb46/volumes/kubernetes.io~iscsi/iscsi-pv
                                                   /var/lib/kubelet/plugins/kubernetes.io/iscsi/iface-default/10.10.150.2:3260-iqn.1992-04.com.emc:storage.Jorsat-NAS01.isci-nas-lun-0
```




