# Introduccion
El presente documento busca detallar la implementacion de un cluster k8s en alta disponibilidad. Aqui veremos como instalar cada nodo del cluster y  de una blanceadora con la solucion HAproxy.

## Escenario planteado
En esta oportunidad utilice HyperV Versión: 10.0.22621.1 para correr las vms correspondientes a los nodos k8s y a la balanceadora HAproxy.
La nueva infraestructura virtual consta de :

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
## Instalacion
Para comenzar vamos a hacer la realizacion de los pre requisitos necesarios  a saber:

> Hacerlo en  Masters y Workers
- Deshabiltar la particion swap de todos los futuros nodos k8s.
- Confiruracion de reglas iptables y de sysctl.
- Instalacion de paquetes necesarios.

En primer lugar deshabilitamos la particion swap:
```
vi /etc/fstab # comentamos o borramos la linea referente a la particion swap
```
## Habilitamos  Netfilter para ContainerD

```
sudo printf "overlay\nbr_netfilter\n" >> /etc/modules-load.d/containerd.conf
sudo modprobe overlay
sudo modprobe br_netfilter
sudo printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\n" >> /etc/sysctl.d/99-kubernetes-cri.conf
sudo sysctl --system
```

## Adaptamos  "overlay" y  "netfilter" para nuestro K8s


```
 cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
 overlay
 br_netfilter
 EOF

 cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
 net.bridge.bridge-nf-call-iptables  = 1
 net.bridge.bridge-nf-call-ip6tables = 1
 net.ipv4.ip_forward                 = 1
 EOF

 sudo sysctl --system

```

<br />
<hr>
