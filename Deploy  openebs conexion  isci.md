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

 Como primer paso nos vamos a posicionar en nuestro namespace llamado openebs con el siguiente comando:

 ```bash
 kubectl config set-context --current --namespace=openebs
```

