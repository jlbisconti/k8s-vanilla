## Introduccion

En este  documento voy a deployar un pod de fauria/vsfptd con el objeto de testear un ftp dentro de mi cluster k8s , para uso externo e interno.

### Creacion del PVC

Vamos a comenzar con la creacion de un PVC para nuestro pod y para ello vamos a crear el archivo pvc.yaml con el siguiente contenido:


 ```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ftp-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

> Nota: Como podemos ver, en este caso, no defini el storageclass, en caso de no tener definido un stoageclass default deberemos especificarlo en nuestro PVC.

## Creacion de el SVC ( service)

A continuacion vamos a crear el archivo svc.yaml donde definimos el svc de la siguinte manera:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ftp-service
spec:
  type: LoadBalancer
  ports:
  - port: 21
    targetPort: 21
    protocol: TCP
    name: ftp
  - port: 30000
    targetPort: 30000
    protocol: TCP
    name: pasv-port1
  - port: 30001
    targetPort: 30001
    protocol: TCP
    name: pasv-port2
  - port: 30002
    targetPort: 30002
    protocol: TCP
    name: pasv-port3
  - port: 30003
    targetPort: 30003
    protocol: TCP
    name: pasv-port4
  - port: 30004
    targetPort: 30004
    protocol: TCP
    name: pasv-port5
  - port: 30005
    targetPort: 30005
    protocol: TCP
    name: pasv-port6
  - port: 30006
    targetPort: 30006
    protocol: TCP
    name: pasv-port7
  - port: 30007
    targetPort: 30007
    protocol: TCP
    name: pasv-port8
  - port: 30008
    targetPort: 30008
    protocol: TCP
    name: pasv-port9
  - port: 30009
    targetPort: 30009
    protocol: TCP
    name: pasv-port10
  selector:
    app: ftp
```

> El servicio creado contempla el acceso externo al estar definido el type como LoadBalancer.

## Creacion del Deployment

Creo el archivo deployment.yaml:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ftp-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ftp
  template:
    metadata:
      labels:
        app: ftp
    spec:
      containers:
      - name: ftp
        image: fauria/vsftpd
        ports:
        - containerPort: 21
        - containerPort: 30000
        - containerPort: 30001
        - containerPort: 30002
        - containerPort: 30003
        - containerPort: 30004
        - containerPort: 30005
        - containerPort: 30006
        - containerPort: 30007
        - containerPort: 30008
        - containerPort: 30009
        volumeMounts:
        - name: ftp-data
          mountPath: /home/vsftpd
        env:
        - name: FTP_USER
          value: "user"
        - name: FTP_PASS
          value: "password"
        - name: PASV_ADDRESS
          value: "192.168.1.100"  # Reemplaza con la IP externa real
        - name: PASV_MIN_PORT
          value: "30000"
        - name: PASV_MAX_PORT
          value: "30009"
        - name: LOCAL_UMASK
          value: "022"
        - name: FILE_OPEN_MODE
          value: "0777"
      volumes:
      - name: ftp-data
        persistentVolumeClaim:
          claimName: ftp-pvc
```

Para finalizar creamos PVC, SVC y deployment:

```bash
kubectl apply -f pvc.yaml
kubectl apply -f svc.yaml
kubectl apply -f deployment.yaml
```

## Comprobaciones finales

Para finalizar comprobamos el status de todo lo creado hasta el momento:

PVC:

```bash
jlb@haproxy:~/test-ftp$ kubectl get pvc
NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
ftp-pvc   Bound    pvc-81620bb5-8342-4223-a705-dea5f8cc01ac   10Gi       RWO            nfs-client     <unset>                 10m
```

Service:

```bash
jlb@haproxy:~/test-ftp$ kubectl get svc -n jorsat-almacenamiento
NAME          TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                                                                                                                                                        AGE
ftp-service   LoadBalancer   10.111.64.206   10.10.100.38   21:31896/TCP,30000:30183/TCP,30001:31254/TCP,30002:32681/TCP,30003:31781/TCP,30004:31790/TCP,30005:31399/TCP,30006:31186/TCP,30007:31964/TCP,30008:30657/TCP,30009:32692/TCP   11m
```

Deployment:

```bash
jlb@haproxy:~/test-ftp$ kubectl get po -n jorsat-almacenamiento
NAME                              READY   STATUS    RESTARTS   AGE
ftp-deployment-65c4657cd8-zlvz6   1/1     Running   0          13m
```


