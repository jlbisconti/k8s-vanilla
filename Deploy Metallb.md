# Introducción

MetalLB es una implementación de Load Balancer para entornos Kubernetes que permite exponer servicios mediante direcciones IP externas en entornos locales o en la nube. Permite a los servicios dentro de un clúster Kubernetes ser accesibles desde fuera del clúster.

En los entornos locales o en la nube que no proporcionan un servicio de Load Balancer integrado, MetalLB puede ser útil para asignar direcciones IP externas a los servicios que necesitan ser accesibles desde fuera del clúster. Utiliza protocolos estándar de enrutamiento, como ARP, NDP y BGP, para anunciar direcciones IP externas y enrutar el tráfico hacia los servicios.

## Componentes de MetalLB

1. **Controlador de MetalLB:** El controlador de MetalLB es el componente principal que gestiona la asignación de direcciones IP y el enrutamiento del tráfico para los servicios expuestos con el tipo de servicio LoadBalancer en Kubernetes. El controlador se ejecuta como un controlador personalizado (Custom Resource Definition - CRD) en el clúster Kubernetes.

2. **Speakers:** Son los componentes que interactúan con la infraestructura de red para anunciar las direcciones IP asignadas por MetalLB y enrutar el tráfico hacia los servicios.

    Hay dos tipos de Speakers:
    - **Speakers de ARP:** Para redes que utilizan el protocolo Address Resolution Protocol (ARP) para el enrutamiento, MetalLB puede utilizar Speakers de ARP para responder a solicitudes ARP y anunciar direcciones IP externas.
    - **Speakers de BGP:** Para redes que utilizan el protocolo Border Gateway Protocol (BGP) para el enrutamiento, MetalLB puede utilizar Speakers de BGP para anunciar las direcciones IP asignadas a través de sesiones BGP con los routers de la red.

## Infraestructura

Esta documentación es referente al despliegue de MetalLB en un clúster Kubernetes vanilla instalado en JORSAT. La infraestructura consta de:

- 1 nodo Master
- 2 nodos worker

El hipervisor utilizado para correr las VMs es VMware® Workstation 17 Pro 17.5.1 build-23298084. El flavor asignado a las VMs fue:
  - 4 CPU
  - 4 GB de RAM
  - 120 GB de disco

## Instalación

Como primer paso, vamos a editar el ConfigMap del componente kube-proxy de Kubernetes con el siguiente comando:

```bash
kubectl edit configmap -n kube-system kube-proxy

# Introducción

MetalLB es una implementación de Load Balancer para entornos Kubernetes que permite exponer servicios mediante direcciones IP externas en entornos locales o en la nube. Permite a los servicios dentro de un clúster Kubernetes ser accesibles desde fuera del clúster.

En los entornos locales o en la nube que no proporcionan un servicio de Load Balancer integrado, MetalLB puede ser útil para asignar direcciones IP externas a los servicios que necesitan ser accesibles desde fuera del clúster. Utiliza protocolos estándar de enrutamiento, como ARP, NDP y BGP, para anunciar direcciones IP externas y enrutar el tráfico hacia los servicios.

## Componentes de MetalLB

1. **Controlador de MetalLB:** El controlador de MetalLB es el componente principal que gestiona la asignación de direcciones IP y el enrutamiento del tráfico para los servicios expuestos con el tipo de servicio LoadBalancer en Kubernetes. El controlador se ejecuta como un controlador personalizado (Custom Resource Definition - CRD) en el clúster Kubernetes.

2. **Speakers:** Son los componentes que interactúan con la infraestructura de red para anunciar las direcciones IP asignadas por MetalLB y enrutar el tráfico hacia los servicios.

    Hay dos tipos de Speakers:
    - **Speakers de ARP:** Para redes que utilizan el protocolo Address Resolution Protocol (ARP) para el enrutamiento, MetalLB puede utilizar Speakers de ARP para responder a solicitudes ARP y anunciar direcciones IP externas.
    - **Speakers de BGP:** Para redes que utilizan el protocolo Border Gateway Protocol (BGP) para el enrutamiento, MetalLB puede utilizar Speakers de BGP para anunciar las direcciones IP asignadas a través de sesiones BGP con los routers de la red.

## Infraestructura

Esta documentación es referente al despliegue de MetalLB en un clúster Kubernetes vanilla instalado en mi infraestura. La infraestructura consta de:

- 1 nodo Master
- 2 nodos worker

El hipervisor utilizado para correr las VMs es VMware® Workstation 17 Pro 17.5.1 build-23298084. El flavor asignado a las VMs fue:
  - 4 CPU
  - 4 GB de RAM
  - 120 GB de disco

## Instalación

Como primer paso, vamos a editar el ConfigMap del componente kube-proxy de Kubernetes con el siguiente comando:

```bash
kubectl edit configmap -n kube-system kube-proxy
Luego, establecemos el campo strictARP en true.

apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true

Después, guardamos los cambios.

Continúa la instalación de MetalLB aplicando el manifiesto:

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/manifests/metallb.yaml

Como tercer paso, vamos a crear los archivos YAML correspondientes al pool de IP's que asignará MetalLB y al archivo L2Advertisement para indicar que vamos a usar capa 2 con ARP como forma de anunciar las IP.

IPPOOL

apiVersion: metallb.io/v1beta1
kind: IPAMConfig
metadata:
  name: config
spec:
  strictAffinity: false
  pools:
  - name: default
    protocol: layer2
    addresses:
    - 10.10.20.20-10.10.20.25 # Estas son IPs de mi LAN y serán las IPs externas

L2Advertisement

apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metallab 
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool

Después de generar estos archivos, los aplicamos con los comandos:

kubectl create -f ippool.yaml
kubectl create -f L2Advertisement.yaml

Luego, verificamos que los pods estén corriendo correctamente:

```bash
kubectl get pods -n metallb-system -o wide


Excelente, aquí tienes la sección actualizada con la salida de los pods de MetalLB:

sql
Copy code
Verificación de la instalación de MetalLB:

Para verificar que MetalLB se ha instalado correctamente y que los pods están en funcionamiento, puedes ejecutar el siguiente comando:

```bash
kubectl get pods -n metallb-system -o wide

Deberías obtener una salida similar a esta:

NAME                         READY   STATUS    RESTARTS   AGE     IP               NODE        NOMINATED NODE   READINESS GATES
controller-756c6b677-l6gmx   1/1     Running   0          2d12h   192.168.37.198   worker-02   <none>           <none>
speaker-8qzfp                1/1     Running   0          2d12h   10.10.20.7      worker-02   <none>           <none>
speaker-db4qn                1/1     Running   0          2d12h   10.10.20.5      master-01   <none>           <none>
speaker-k825x                1/1     Running   0          2d12h   10.10.20.15     worker-01   <none>           <none>


Configuramos nuestro kubernes dashboard para que Metallb le asigne la ip externa Para esto editamos el servicio referente kubernetes-dashboards con el comando:

kubectl edit svc kubernetes-dashboard -n kubernetes-dashboard

Solo modificamos el campo type para que quede como LoadBalancer:

apiVersion: v1
kind: Service
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"k8s-app":"kubernetes-dashboard"},"name":"kubernetes-dashboard","namespace":"kubernetes-dashboard"},"spec":{"ports":[{"port":443,"targetPort":8443}],"selector":{"k8s-app":"kubernetes-dashboard"}}}
    metallb.universe.tf/ip-allocated-from-pool: first-pool
  creationTimestamp: "2024-04-05T21:11:58Z"
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
  resourceVersion: "76859"
  uid: 4f15f27c-8ad6-4235-89d5-77198eb201c7
spec:
  allocateLoadBalancerNodePorts: true
  clusterIP: 10.103.93.204
  clusterIPs:
  - 10.103.93.204
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - nodePort: 31796
    port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
  sessionAffinity: None
  type: LoadBalancer

Y guardamos .

Luego ejecutamos el comando :
```bash kubectl get  svc kubernetes-dashboard -n kubernetes-dashboard

jlb@master-01:~$ kubectl get  svc kubernetes-dashboard -n kubernetes-dashboard
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)         AGE
kubernetes-dashboard   LoadBalancer   10.103.93.204   10.10.20.20   443:31796/TCP   46h

Como podemos ver tomo external IP desl rango creado en Metallb






