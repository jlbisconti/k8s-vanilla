## Introduccion

Esta es una guia breve orientada al deploy de la plataforma multimedia plex dentro de un  cluster k8s vanilla.

## Escenario planteado

Vamos a montar plex dentro de nuestro cluster k8s vanilla. Nuestra infraestructura montada sobre  HyperV Versión: 10.0.22621.1 es la siguiente:

- 3 nodo Master
- 1 nodo  worker ( por el momento)
- 1 Balancerador HAproxy
- SO Ubuntu 22.04 Server en todas las vms
  
  El flavor asignado a las VMs fue:
  Nodos k8s:
  - 4 CPU
  - 4 GB de RAM
  - 120 GB de disco
 Balanceadora Haproxy:
  - 1 CPU
  - 1 GB
  - 15 GB de disco

## Deploy de plex

Comenzaremos creando el  configuracion de storage persistente de plex. Vamos a necesitar :

- Crear el PV
- Crear el PVC
- Aplicar los archvos yaml correspondientes

> Nos situamos en el namespace microservicios ya creado en las guias anteriores con el comando: kubectl config set-context --current --namespace=microservicios


Creamos  PV (Persistent Volume) generando el archivo pv-plex.yaml:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: plex-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.10.150.2 # Colacar ip segun corresponda a cada caso.
    path: /nfs/plex  #Colacar path de nuestro NFS segun corresponda a cada caso.
  ```

A continuacion creamos nuestro PVC ( Persistent Volume Claim) generando el archivo  pvc-plex.yaml:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: plex-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
  ```

Aplicamos las configuraciones:

```
kubectl apply -f pv-plex.yaml
kubectl apply -f  pvc-plex.yaml
```

Ahora verificamos el status de ambos con el comando:

```
kubectl get pv,pvc
```

Vamos a comprobar al instante que tanto PV como PVC estan en estado Bound.

Como paso siguiente crearemos el archivo deployment_plex_nfs.yaml:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: plex-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: plex
  template:
    metadata:
      labels:
        app: plex
    spec:
      containers:
      - name: plex
        image: plexinc/pms-docker:latest
        ports:
        - containerPort: 32400
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "2"
        volumeMounts:
        - name: plex-data
          mountPath: /config
      volumes:
      - name: plex-data
        persistentVolumeClaim:
          claimName: plex-pvc
  ```

 ```
kubectl apply -f deployment_plex_nfs.yaml
```

Comprobamos el status del pod de plex  con el comando:

```bash
kubectl get po
```

En nuesttro vamos a ver el pod en estado running:

>plex-deployment-77d7f495b4-f8zz9       1/1     Running

Ahora procedemos  a la creacion del servicio para darle acceso externo a plex. Crearemos un servicio de tipo LoadBalancer aprovechando que ya tenemos funcionando metallb en nuestro cluster. Creamos el archivo  plex_svc.yaml:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: plex-service
spec:
  type: LoadBalancer
  selector:
    app: plex
  ports:
    - protocol: TCP
      port: 80
      targetPort: 32400
```

```bash
kubectl apply -f plex_svc.yaml
```

Verificamos el servicio creado con el comando:

```bash
kubectl get svc

NAME               TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)          
plex-service       LoadBalancer   10.106.181.249   10.10.100.34   80:31224/TCP     
```


> Nota: Nuestro NAS no debe no debe tener habilitada la opcion Allow root acount acces. Por otor lado cuando la carpeta config de plex esta en 3.9 MB de tamaño podremos ver que ya estara accesible plex. 



Como podemos ver el servicio se creo. Nuestra balanceadora metallb le proporciono la ip 10.10.100.34 de nuestra LAN con acceso al puerto 80. Con este informacion podemos comprobar en nuestro browser preferido:

![image](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/a9bc4069-b928-4041-80d4-34ea00ff8405)







Exitos!!!!

