# Introduccion
El presente documento busca detallar la implementacion de un cluster k8s en alta disponibilidad. Aqui veremos como instalar cada nodo del cluster y  de una blanceadora con la solucion HAproxy.

## Escenario planteado
En esta oportunidad utilice HyperV Versión: 10.0.22621.1 para correr las vms correspondientes a los nodos k8s y a la balanceadora HAproxy. Nuestra balanceadora va exponer con su propia IP el puerto 6443 a modo de VIP. Todos nuestros nodos master se van a deployar apuntando a nuestra balanceadora.
La nueva infraestructura virtual consta de :

- 3 nodo Master
- 3 nodos worker 
- 1 Balancerador HAproxy
- SO Ubuntu 22.04 Server en todas las vms
  
  El flavor asignado a las VMs fue:
  Nodos k8s:
  
  Masters:
  - 4 CPU
  - 4 GB de RAM
  - 120 GB de disco
    
  Workers:
 - 4 CPU
  - 16 GB de RAM
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
> Colocar las ips y nombres de host correspondientes para cada  caso

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

Comprobamos  con nc que responda en el puerto 6443

```bash
  nc -v localhost 6443
  Connection to localhost 6443 port [tcp/*] succeeded!
 ```

Instalamos los paquetes de kubernestes :

 ```
 sudo apt-cache search kubeadm && apt-cache search kubelet && apt-cache search kubectl
 sudo apt install kubeadm kubelet kubectl -y
  ```
Marcamos los paquetes para que no sean upgradeables

```
sudo apt-mark hold kubeadm kubelet kubectl
```


## Instalacion nodos k8s

> Los siguientes pasos de instalacion se realizaran tanto en nodos master como en workers

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

> Agregramos el repo:
 ```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
 ```

Instalamos containerd:
 ```
sudo apt-cache search containerd
sudo apt install containerd -y
sudo mkdir /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd.service
sudo systemctl enable --now containerd
sudo systemctl start --now containerd
sudo systemctl status containerd
sudo systemctl restart containerd
 ```

> confirmar si los paquetes requeridos están disponibles en el repositorio
 ```
 apt-cache search kubeadm && apt-cache search kubelet && apt-cache search kubectl
 ```
Instalar los paquetes:

```
sudo apt install kubeadm kubelet kubectl -y
 ```

> Marcar los paquetes  que no deben ser upgradeados en el proximo apt upgrade

 ```
 sudo apt-mark hold kubeadm kubelet kubectl
 sudo systemctl enable kubelet.service
 sudo reboot
 sudo systemctl status kubelet.service
 sudo systemctl restart kubelet.service
 ```

## Inicializamos el cluster de kubernes 

Comenzamos con nuestro nodo master-01:

```
sudo kubeadm init --control-plane-endpoint 10.10.100.21:6443 --upload-certs --pod-network-cidr=192.168.0.0/16 
```

Luego de tener nuestro nodo master-01 vamos a instalar calico como CNI para el manejo de las redes de nuestro cluster.

Descargamos calico:

```
wget https://docs.projectcalico.org/manifests/calico.yaml
```

Luego aplicamos el archivo calico.yaml:

```
kubectl apply -f calico.yaml
```
En unos minutos veremos que nuestro nodo esta en estado ready:
```
NAME        STATUS   ROLES           AGE    VERSION
master-01   Ready    control-plane   2m    v1.29.4
```
A continuacion  procedemos a joinear los nodos master-02 y master-03 con el siguiente comando:

```bash
sudo kubeadm join 10.10.100.24:6443 --token 152el8.p0ajifpi371yawc0 \
        --discovery-token-ca-cert-hash sha256:c352f0b3740a2db9448dd438921bb350113b459447a2bddbbce9a80ae86c9e9d \
        --control-plane --certificate-key 187bb2675840bb108b5293aec3ab9c301996ff31a5b61f4059537ccc5245068f
```
> Siempre tener en cuenta que los valores de los flags token, --discovery-token-ca-cert-has y -certificate-key son unicos en cada join de nodos con lo cual deben  colocar los valores resultantes del comando  kubeadm init de nuestro primer nodo master.

Ahora chequiemos que los pod del namespace kube-system esten distribuidos en los tres nodos master. 

Ejecutamos el comando 

```bash
 kubectl get po -n kube-system 
```
Deberemos ver que tenemos lso siguintes pods criticos:
```
kube-scheduler-master-01                  
kube-scheduler-master-02                
kube-scheduler-master-03

kube-controller-manager-master-01       
kube-controller-manager-master-02          
kube-controller-manager-master-03

kube-apiserver-master-01                   
kube-apiserver-master-02                   
kube-apiserver-master-03

etcd-master-01                           
etcd-master-02                          
etcd-master-03 
```

Join de nuestro nodo worker:
```
sudo kubeadm join 10.10.100.24:6443 --token 152el8.p0ajifpi371yawc0 \
        --discovery-token-ca-cert-hash sha256:187bb2675840bb108b5293aec3ab9c301996ff31a5b61f4059537ccc5245068f
```


## Pasos finales

AL final de este doc lo que haremos es copiar el path .kube/config desde cualquier nodo master del cluster hacia el home de nuestra balanceadora HAproxy ya que necesita la config de auth de los api server

```
scp admin.conf  jlb@10.10.100.21:/home/jlb/

```

Finalmnete resta probar reiniciando nodos mater para comprobar que el cluster sigue disponible. Podemos chequear los logs de Haproxy para verificar que marque como DOWN el master reiniciado y los demas UP.



