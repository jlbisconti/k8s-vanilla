# Introduccion

En este documento breve voy a describir los pasos para deployar la plataforma de machine learning llamada kubeflow. En una proxima documentacion voy a abarcar pruebas desde la plataforma ya instalada.

## Escenario planteado

Frenta a la necesidad de la realizacion de pruebas de plataformas de machine learning  y redes neuronales, se decidio comenzar por kubeflow.

Nuestra  infraestructura consta de:

- 3 nodos Master
- 3 nodos worker
- 1 blanceadora haproxy
- SO Ubuntu 22.04 Server en todas las vms

El flavor asignado a las VMs fue:

Nodos k8s:
Masters:
4 CPU
4 GB de RAM
120 GB de disco

Nodos worker:
4 CPU
16 GB de RAM
120 GB de disco.

Balanceadora Haproxy:
1 CPU
4 GB
65 GB de disco

Ip planning

Balanceadora 10.10.100.21
Master-01 10.10.100.22
Master-02 10.10.100.23
master-03 10.10.100.24
worker-01 10.10.100.25
worker-02 10.10.100.26
worker-03 10.10.100.27

## Instalacion

EL primer paso sera  crear una carpeta llamada kubeflow y posicinarnos en ella :

```
mkdir kubeflow
cd kubeflow
```

Luego clonamos el repositorio de kubeflow en github:

```
git clone <https://github.com/kubeflow/manifests.git>
```

Nos movemos al directorio manifiests:

```
cd manifests
```

Como siguiente paso vamos a instalar kustomize con el comando:

```
sudo snap install  kustomize
```

Ahora vamos a crear todos los recuros de kubeflow utilizando las herramientas  kustomize y kubectl:

```
while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
```

Luego verificamos los pods creados y en estado running:

```
kubectl get po -A
```
Vamos a poder ver el status de los pods de manera similar a la siguiente imagen:



![pods](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/4d479981-ad10-4aca-a1f7-adeda087c28d)


