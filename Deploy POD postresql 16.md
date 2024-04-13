# Introducción
En este documento vamos a detallar el deploy de un POD Posgres version 16 sobre mi cluster k8s. Veremos el paso a paso para crear el pvc (Persistent Volume Claim), el deployment, el servicio para exponer a postgres desde fuera del cluster y la prueba de conexion externa al POD.

## Escenario planteado
 Tenemos un cluster que consta de:

 - 1 nodo Master
- 3 nodos worker
- SO Ubuntu 22.04 Server 

El hipervisor utilizado para correr las VMs es VMware® Workstation 17 Pro 17.5.1 build-23298084. El flavor asignado a las VMs fue:
  - 4 CPU
  - 4 GB de RAM
  - 120 GB de disco

En esta oportunidad seguiremos creando nuestros pod sobre el servidor NFS proporcionado por nuestros NAS Iomega. 

## Instalacion
 Como primer paso nos vamos a posicionar en nuestro namespace llamado microservicios con el siguiente comando:

 ```bash
 kubectl config set-context --current --namespace=microservicios
```
Una vez en nuestro namespace vamos a proceder a crear nuestro pvc (Persistent Volume Claim) creando el archivo .yaml correspondiente.

 ```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-client
  resources:
    requests:
      storage: 1Gi
 ```
Luego crearemos el pvc con el comando:

 ```bash
kubectl create -f postgres-pvc.yaml
 ```
Ahora verificamos el status en que se  encuentra nuestro pvc :

 ```bash
 kubectl get pvc
 ```
Vamos a obtene una salida similar a la siguinte:

 ```
 NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    VOLUMEATTRIBUTESCLASS   AGE
postgres-pvc   Bound    pvc-454985c9-3696-4ce0-b891-9f94e14b7d0b   1Gi        RWO            nfs-client      <unset>                 56m
 ```

Podemos verificar  que el pvc esta en estado Bound ya que creo el pv (Phisical Volume) llamado pvc-454985c9-3696-4ce0-b891-9f94e14b7d0b con el tamaño de 1 GB.

Ahora pasaremos a crear nuestro archivo .yaml correspondiente al deployment del POD con el siguiente contenido:

 ```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:latest
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: "tucontraseña" # Colcamos nuestra contraseña
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
 ```
Verificamos el status de nuestro pod:

 ```bash
jlb@master-01:~$ kubectl get po -o wide
NAME                                   READY   STATUS    RESTARTS        AGE   IP                NODE        NOMINATED NODE   READINESS GATES
postgres-deployment-7d76798d6b-5cd8h   1/1     Running   0               66m   192.168.202.198   worker-03   <none>           <none>
 ```
Como podemos ver nuestro pod se encuentra corriendo en nuestro nodo worker-03.
A continuacion crearemos el servicio de typo Loadbalancer pr el cual Metallb nos proporcionara una ip externa de su pool y el PAT ( Port Address Translation) necesario para hacer visible nuestro POD desde afuera del cluster  k8s.  

Creamos  el archivo postgres-svc.yaml con siguiente contenido:

 ```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  type: LoadBalancer
```
Con el siguiente comando verificamos el servicio:

 ```bash
kubectl get svc
```

La salida deberia ser similar a la siguiente 
 ```
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
postgres-service   LoadBalancer   10.96.204.86    10.10.100.22   5432:30718/TCP   70m
 ```

Como podemos ver el servicio se creo correctamente y tiene la ip 10.10.100.22 para acceder externamente a nuestro postgres.

## Configuracion de postgres 16

Como primer paso vamos a ingresar al POD con el comando: 

 ```bash
 kubectl exec -it postgres-deployment-7d76798d6b-5cd8h /bin/bash
```
Tener en cuenta que en cada caso el pod va recibir un nombre distinto.

Una vez dentro del POD vamos a crear el cluster de postgres con el siguiente comando:
 ```bash
pg_createcluster 16 main --start
 ```
Como paso siguiente vamos a iniciar el servicio de postgres con el comando:
 ```bash
pg_ctlcluster 16 main start
 ```
Comprobamos el status del servicio postgres:
 ```bash
service postgresql status
 ```
Vamos a ver una salida como esta:
```
16/main (port 5433): online
```
## Conexion externa a postgres , Prueba del POD.

Para finalizar vamos a conectarnos a el servicio postgres de nuestro POD. En este caso decidi realizar la prueba con la aplicacion pgadmin4.

1 - Desargamos la aplicacion pgadmin4 desde el siguiente link [pgadmin4](https://www.pgadmin.org/download/pgadmin-4-windows/)

Descargamos la ultimna version. Al momento de la realizacion de este documento, la version 8.5.

2 - Luego de instalar la aplicacion pgadmin4 vamos a crear la conexion: 



![pgadmin-1](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/21c4996f-cf96-49e0-b561-ac2a61ebcaab)


![pgadmin-2](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/171e1adf-01fd-46eb-9f68-66c571e2f892)

![pgadmin-3](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/c8a6654a-3880-4438-aba1-d8c391fec7fb)


Una vez cargados todos los parametros presionamos el boton save y veremos como la aplicacion pgadmin4 se conecta a nuestra db postgres perteneciente al POD creado:

![pgadmin-4](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/3580dcc5-3f0b-4b3a-9624-e519dac630ba)















