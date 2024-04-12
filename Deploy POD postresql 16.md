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



