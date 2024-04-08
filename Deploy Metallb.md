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
  - 
## Instalación

Como primer paso, vamos a editar el ConfigMap del componente kube-proxy de Kubernetes con el siguiente comando:

```bash

kubectl edit configmap -n kube-system kube-proxy
```
Luego, establecemos el campo strictARP en true.

```bash
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```

Continuamos la instalación de MetalLB aplicando el manifiesto:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/manifests/metallb.yaml
```
Como tercer paso, vamos a crear los archivos YAML correspondientes al pool de IP's que asignará MetalLB y al archivo L2Advertisement para indicar que vamos a usar capa 2 con ARP como forma de anunciar las IP.

IPPOOL
```yaml
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
```














