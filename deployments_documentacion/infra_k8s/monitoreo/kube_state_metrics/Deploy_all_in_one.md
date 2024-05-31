# Introduccion 

Al montar el monitoreo de nuestro cluster k8s nos vamos a encontar con la necesidad de deployar distintos componentes que obtienen metricas. Hasta el momento habiamos deployado:

- promethues
- node-exporter ( tambien podemos optar por prometheus-node-exporter)

Ahora vamos a realizar los pasos para deployar kube-state-metrics. 

## ¿Qué es kube-state-metrics?

kube-state-metrics es un servicio de monitoreo que se ejecuta dentro de un clúster de Kubernetes. Está diseñado para generar métricas sobre el estado de los recursos de Kubernetes y exponer estas métricas en un formato compatible con Prometheus.

## ¿Qué hace kube-state-metrics?

Recolecta el estado de los recursos de Kubernetes:

kube-state-metrics se conecta a la API de Kubernetes y recopila información sobre el estado de varios recursos del clúster, como nodos, pods, servicios, deployments, entre otros.
Genera métricas:

A partir de la información recolectada, kube-state-metrics genera métricas detalladas sobre estos recursos. Estas métricas proporcionan datos valiosos sobre la salud y el estado de los recursos de Kubernetes.
Por ejemplo, puede generar métricas sobre:
El estado de los nodos (si están listos, no listos, etc.).
El número de pods en diferentes estados (ejecutándose, fallando, pendientes, etc.).
El uso de recursos como CPU y memoria por parte de los pods.
La disponibilidad de los servicios y endpoints.

## Imnplementacion

Para poder deplegar kube-state-metrics vamos a correr el archivo all_in_one_deploy.yaml  que contiene todo lo necesario  para que kube-state-metrics quede operativo:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kube-system


---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-state-metrics
  namespace: kube-system
  labels:
    app: kube-state-metrics
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-state-metrics
  template:
    metadata:
      labels:
        app: kube-state-metrics
    spec:
      containers:
      - name: kube-state-metrics
        image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.7.0
        ports:
        - name: http
          containerPort: 8080
        - name: telemetry
          containerPort: 8081
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          timeoutSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          timeoutSeconds: 5
      serviceAccountName: kube-state-metrics


---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-state-metrics
  namespace: kube-system


---
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics
  namespace: kube-system
  labels:
    app: kube-state-metrics
spec:
  ports:
  - name: http
    port: 8080
    targetPort: http
  selector:
    app: kube-state-metrics


---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
rules:
- apiGroups: [""]
  resources:
  - configmaps
  - secrets
  - nodes
  - pods
  - services
  - resourcequotas
  - replicationcontrollers
  - limitranges
  - persistentvolumeclaims
  - persistentvolumes
  - namespaces
  - endpoints
  verbs: ["list", "watch"]
- apiGroups: ["extensions"]
  resources:
  - daemonsets
  - deployments
  - replicasets
  - ingresses
  verbs: ["list", "watch"]
- apiGroups: ["apps"]
  resources:
  - statefulsets
  - daemonsets
  - deployments
  - replicasets
  - cronjobs
  - jobs
  verbs: ["list", "watch"]
- apiGroups: ["batch"]
  resources:
  - jobs
  - cronjobs
  verbs: ["list", "watch"]
- apiGroups: ["autoscaling"]
  resources:
  - horizontalpodautoscalers
  verbs: ["list", "watch"]
- apiGroups: ["policy"]
  resources:
  - poddisruptionbudgets
  verbs: ["list", "watch"]
- apiGroups: ["certificates.k8s.io"]
  resources:
  - certificatesigningrequests
  verbs: ["list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources:
  - networkpolicies
  verbs: ["list", "watch"]


---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-state-metrics
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-state-metrics
subjects:
- kind: ServiceAccount
  name: kube-state-metrics
  namespace: kube-system
```

Con esto vamos a tener desplegado kube-state-metrics de mmanera de poder tener mejores metricas para trabajar con promethues!!!!.