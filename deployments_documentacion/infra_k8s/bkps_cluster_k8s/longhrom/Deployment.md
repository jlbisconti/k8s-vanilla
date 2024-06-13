# Introduccion

## Longhorn

Longhorn es una solución robusta y escalable para proporcionar almacenamiento persistente confiable dentro de clústeres de Kubernetes, orientada a simplificar la gestión y protección de datos para aplicaciones distribuidas en entornos de contenedores.

Características principales de Longhorn:
Almacenamiento Distribuido: Longhorn distribuye los datos a través de múltiples nodos en un clúster de Kubernetes, asegurando redundancia y alta disponibilidad.

Replicación y Snapshots: Ofrece replicación automática de datos para tolerancia a fallos y permite la creación de instantáneas (snapshots) para puntos de restauración de datos.

Gestión desde Kubernetes: Se integra de manera nativa con Kubernetes, lo que significa que se puede administrar y controlar a través de la API de Kubernetes y herramientas estándar como kubectl.

Persistencia para Estado de Aplicaciones: Permite que las aplicaciones en contenedores en Kubernetes puedan almacenar datos de manera persistente, incluso después de que los contenedores se hayan reiniciado o escalado.

Interfaz de Usuario Gráfica (UI): Longhorn proporciona una interfaz de usuario web para administrar volúmenes, snapshots y backups de manera visual.

Backups y Restauración: Facilita la creación de backups y restauración de datos, lo que es esencial para la protección y recuperación ante desastres.

Escalabilidad y Rendimiento: Está diseñado para escalar horizontalmente con el crecimiento del clúster de Kubernetes, y ofrece un rendimiento optimizado para aplicaciones que requieren acceso rápido a datos.

En este documento vamos a detrallar los pasos para el deploy de Longhorn en k8s y en un proximo documento vamos a probar como realizar backups con esta herramienta.

## Deploy

Vamos a optar por helm para realizar el despliegue de Longhorm dentro de nuestro cluster k8s llamado jorsat. Para ello vamos a utilizar los comandos:

```
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

Con estos comandos agregamos el repo helm de Longhorn y lo actualizamos. Luego vamos a crear el namespace:

```
kubectl create namespace longhorn-system
```

Ahora procedemos a deployar Longhorn:

```
helm install longhorn longhorn/longhorn --namespace longhorn-system
```

 Podemos verficar el estatus de todos los pods:

```
 jlb@haproxy:~$ kubectl get po
NAME                                                READY   STATUS      RESTARTS      AGE
backing-image-manager-b2c6-d317                     1/1     Running     0             15s
c-1tmzo5-28637280-dg48s                             0/1     Completed   0             15s
csi-attacher-86dfbdcc4d-98kjj                       1/1     Running     0             15s
csi-attacher-86dfbdcc4d-kbmcv                       1/1     Running     0             20s
csi-attacher-86dfbdcc4d-wnzlf                       1/1     Running     0             20s
csi-provisioner-8dfb9c8cd-cxgwz                     1/1     Running     0             20s
csi-provisioner-8dfb9c8cd-g6clb                     1/1     Running     0             20s
csi-provisioner-8dfb9c8cd-r6727                     1/1     Running     0             20s
csi-resizer-867db76d64-7w5zt                        1/1     Running     0             20s
csi-resizer-867db76d64-jvpg2                        1/1     Running     0             20s
csi-resizer-867db76d64-lwc9b                        1/1     Running     0             20s
csi-snapshotter-7d444967ff-75hqg                    1/1     Running     0             23s
csi-snapshotter-7d444967ff-7ngmj                    1/1     Running     0             23s
csi-snapshotter-7d444967ff-vfmvs                    1/1     Running     0             23s
engine-image-ei-b0369a5d-d8h7x                      1/1     Running     0             23s
engine-image-ei-b0369a5d-wpb5l                      1/1     Running     0             23s
engine-image-ei-b0369a5d-xmhjx                      1/1     Running     0             23s
engine-image-ei-b907910b-565gx                      1/1     Running     0             30s
engine-image-ei-b907910b-5l4d6                      1/1     Running     0             30s
engine-image-ei-b907910b-g9n62                      1/1     Running     0             30s
instance-manager-34cb1beca8cba447fe641204cc1c87d9   1/1     Running     0             30s
instance-manager-3ba1d40724458957e1516de68d8dcea8   1/1     Running     0             30s
instance-manager-69cefdc6b93f3dc5b24cb8522cff3865   1/1     Running     0             44s
instance-manager-84c7c6caa2694614e0440149c35ae3e2   1/1     Running     0             44s
instance-manager-b389e5d8c1bdb929a3866884c5c9f7f7   1/1     Running     0             44s
instance-manager-f1037cf61535e4110c2a5703d6946075   1/1     Running     0             44s
longhorn-csi-plugin-4mtgb                           3/3     Running     0             44s
longhorn-csi-plugin-8cl8p                           3/3     Running     0             44s
longhorn-csi-plugin-gxbm9                           3/3     Running     0             48s
longhorn-driver-deployer-f8679bf7d-8sfht            1/1     Running     2 (45m ago)   48s
longhorn-manager-4j2gn                              1/1     Running     0             48s
longhorn-manager-bfhbk                              1/1     Running     0             48s
longhorn-manager-cfdks                              1/1     Running     0             48s
longhorn-ui-b5c5fc79c-jf7tt                         1/1     Running     0             48s
longhorn-ui-b5c5fc79c-nlgdn                         1/1     Running     0             48s
```

Ahora vamos a modificar el servicio longhorn-frontend para que obtenga una IP externa de nuestra LB metallb:

```
kubectl edit svc longhorn-frontend
```

Vamos a cambiar el valor type de ClusterIp a LoadBalancer y nos quedara de la siguiente manera:

```yaml
 apiVersion: v1
    kind: Service
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
  9       {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"app":"longhorn-ui","app.kubernetes.io/instance":"longhorn","app.kubernetes.io/name":"longhorn",    "app.kubernetes.io/version":"v1.6.0-dev"},"name":"longhorn-frontend","namespace":"longhorn-system"},"spec":{"ports":[{"name":"http","nodePort":null,"port":80,"targetPort":"http"    }],"selector":{"app":"longhorn-ui"},"type":"ClusterIP"}}
       meta.helm.sh/release-name: longhorn
       meta.helm.sh/release-namespace: longhorn-system
       metallb.universe.tf/ip-allocated-from-pool: first-pool
     creationTimestamp: "2024-06-11T21:20:54Z"
     labels:
        app: longhorn-ui
        app.kubernetes.io/instance: longhorn
        app.kubernetes.io/managed-by: Helm
        app.kubernetes.io/name: longhorn
        app.kubernetes.io/version: v1.6.0-dev
        helm.sh/chart: longhorn-1.6.2
     name: longhorn-frontend
     namespace: longhorn-system
     resourceVersion: "2797185"
      uid: 7b38815d-d3fc-45f9-9766-ed85f0137bc4
    spec:
    allocateLoadBalancerNodePorts: true
    clusterIP: 10.99.70.3
    clusterIPs:
    - 10.99.70.3
    externalTrafficPolicy: Cluster
    internalTrafficPolicy: Cluster
      ipFamilies:
      - IPv4
      ipFamilyPolicy: SingleStack
      ports:
     - name: http
       nodePort: 31138
      port: 80
      protocol: TCP
      targetPort: http
    selector:
      app: longhorn-ui
    sessionAffinity: None
    type: LoadBalancer
  status:
    loadBalancer:
      ingress:
      - ip: 10.10.100.40
```
AHora vamos a ingreasar a la GUI de Longhorn desde nuestro browser a la IP 10.10.100.40 tal como lo muestra la siguiente imagen:



![gui-longhron](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/bc9dbe68-8e0d-4533-82e1-380a3332cd56)

Hasta el proximo Documento!!!

