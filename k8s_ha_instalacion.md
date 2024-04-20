# Introduccion
El presente documento busca detallar la implementacion de un cluster k8s en alta disponibilidad. Aqui veremos como instalar cada nodo del cluster y  de una blanceadora con la solucion HAproxy.

## Escenario planteado
En esta oportunidad utilice HyperV Versión: 10.0.22621.1 para correr las vms correspondientes a los nodos k8s y a la balanceadora HAproxy. Nuestra balanceadora va exponer con su propia IP el puerto 6443 a modo de VIP. Todos nuestros nodos master de van a deployar apuntando a nuestra balanceadora.
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

Ip planning

 - Balanceadora HAproxy : 10.10.100.21
 - Master-01 10.10.100.22
 - Master-02 10.10.100.23
 - master-03 10.10.100.24

Para comenzar vamos a hacer la realizacion de los pre requisitos necesarios  a saber:

> Pasos de instalacion y configuracion de HAproxy
 - Instalamos paquete HAproxy
 - Realizamos la configuracion del balanceo
 - Posterior a la instalacion de los nodos master copiaremos .kube/config y certificados

> Hacerlo en  Masters y Workers
- Deshabiltar la particion swap de todos los futuros nodos k8s.
- Confiruracion de reglas iptables y de sysctl.
- Instalacion de paquetes necesarios.


## Instalacion de HAproxy


Comenzamos con la instalacion del paquete:

```
sudo apt-get install haproxy -y
```
Editamos la configuracion con el comando:

```
sudo vim /etc/haproxy/haproxy.cfg
```
Nuestra configuracion sera la siguiente:
> Colocar las ips y nombres de host correspondientes para caso

```yaml
frontend fe-apiserver
   bind 0.0.0.0:6443
   mode tcp
   option tcplog
   timeout client 30s
   timeout connect 5s
   timeout server 30s
   default_backend be-apiserver

backend be-apiserver
   mode tcp
   option tcp-check
   balance roundrobin
   default-server inter 10s downinter 5s rise 2 fall 3 slowstart 60s maxconn 250 maxqueue 256 weight 100 check
   timeout connect 5s
   timeout server 30s
   server master-01 10.10.100.22:6443 check fall 3 rise 2
   server master-02 10.10.100.23:6443 check fall 3 rise 2
   server master-03 10.10.100.24:6443 check fall 3 rise 2
```

Reiniciamos el servicio:

```bash
systemctl restart haproxy
systemctl status haproxy
```
> Aseguremosnos que HAproxy tenga su servicio en estado running

Comprobamos 
  

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

# Instalacion de paquetes necesarios

> confirmar si los paquetes requeridos están disponibles en el repositorio
 ```
 apt-cache search kubeadm && apt-cache search kubelet && apt-cache search kubectl
 ```
Instalar los paquetes:

```
sudo apt install kubeadm kubelet kubectl -y
 ```

> Marcar los paquetes  que no deben ser upgradeados en el proximo'apt upgrade'

 ```
 sudo apt-mark hold kubeadm kubelet kubectl
 sudo systemctl enable kubelet.service
 sudo reboot
 sudo systemctl status kubelet.service
 sudo systemctl restart kubelet.service
 ```




