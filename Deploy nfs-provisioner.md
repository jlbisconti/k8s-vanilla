# Introduccion 
## Escenario planteado
Realize la instalacion de un cluster k8s vanilla al que le deploye un load balancer por software, a saber Metallb y se configo un servidor NFS para dar persistencia los POD's que lo requieran 

  Como comente anteriormente la infraestructura consta de:

- 1 nodo Master
- 2 nodos worker
- SO Ubuntu 22.04 Server 

El hipervisor utilizado para correr las VMs es VMware® Workstation 17 Pro 17.5.1 build-23298084. El flavor asignado a las VMs fue:
  - 4 CPU
  - 4 GB de RAM
  - 120 GB de disco

## Solucion NFS seleccionada

En este caso opte por la solucion nfs-provisioner. La misma es una implementación de un provisionador de almacenamiento para Kubernetes que utiliza el protocolo NFS para proporcionar almacenamiento persistente a las aplicaciones desplegadas en un clúster de Kubernetes.

## Instalacion

### Prerrequisito, Paquete cliente NFS en nodos de K8s
Es fundamental que  que todos los nodos de Kubernetes tengan los paquetes cliente NFS disponibles.  En este caso necesitamos del paquete  nfs-common instalado en todos los nodos worker de K8s.
Instalaremos el paquete nfs-common con el siguiente comando:

```bash
sudo apt update
sudo apt install nfs-common -y
```
Una vez instalado el paquete nfs-common en todos los nodos worker vamos a utilizar el comando showmount para verificar la ruta en la que esta exportando el share  nuestro servidor nfs:

```bash
showmount -e 10.10.50.2
```
En nuestro caso la salida  obtenida  fue 
Export list for 10.10.50.2:
/mnt/soho_storage/samba/shares/kubernetes *

### Instalacion de Helm
#### ¿que es Helm?
Helm es una herramienta de gestión de paquetes para Kubernetes que facilita la implementación, actualización y administración de aplicaciones en clústeres de Kubernetes. Permite definir, instalar y actualizar fácilmente aplicaciones complejas con múltiples componentes en Kubernetes utilizando un formato de paquete estandarizado llamado "chart".

Los charts de Helm son como scripts que describen una aplicación de Kubernetes, incluyendo los recursos de Kubernetes necesarios (como despliegos, servicios, secretos, etc.), configuraciones predeterminadas y valores personalizables. Con Helm, los desarrolladores pueden crear charts para empaquetar y distribuir sus aplicaciones de Kubernetes de manera coherente y reutilizable.

#### Instalacion

Para instalar Helm en nuestro nodo master  vamos a descragarlo de su sitio oficial con el el siguiente comando:

```bash
wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
```
Luego vamos a descomprimir el archivo .tar.gz y moverlo a la carpeta /usr/local/bin para tenerlo disponible desde cualquier ubicacion:

```bash
tar -zxvf helm-v3.12.0-linux-amd64.tar.gz
sudo mv linux-amd64/ /usr/local/bin/
chmod +x /usr/local/bin/helm
```
### Instalacion de repositorio nfs-provioner
```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
```
### Creacion de namespace nfs-provicioner en k8s-vanilla
```bash
kubectl create namespace  nfs-provicioner
```
### Instalacion del Helm chart para NFS

El siguiente ejemplo corresponde a mi servidor NAS.
```bash
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=10.10.150.2 --set nfs.path=/nfs/kubernetes --set storageClass.onDelete=true
```

### Comprobaciones 

En primer lugar vamos a comprobar que se encuentre creado el storage class correspondiente:
```bash
 kubectl get storageclass nfs-client
```
```bash
NAME         PROVISIONER                                     RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-client   cluster.local/nfs-subdir-external-provisioner   Delete          Immediate           true                   27h
```bash

### Creacion de PVC (Persitent Volume Clain)












