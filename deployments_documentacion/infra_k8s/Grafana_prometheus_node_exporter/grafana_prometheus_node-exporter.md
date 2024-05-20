# Introduccion

En este documento vamos a conectar un servidor grafana con Pods de prometheus y nodo-exporter de nuestro cluster k8s.

## Escenario planteado

En esta oportunidad utilice HyperV Versión: 10.0.22621.1 para correr las vms correspondientes a los nodos k8s y al servidor Grafana.
La  infraestructura virtual consta de :

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
Servidor Grafna:
- 4 CPU
- 4 GB
- 60 GB de disco

Ip planning

- Servidor Grafana : 10.10.100.24
- Master-01 10.10.100.22
- Master-02 10.10.100.25
- Master-03 10.10.100.27
- Worker-01 10.10.100.26
- Worker-02 10.10.100.28
- Worker-03 10.10.100.29

### Deploy de prometheus-server

El primer paso es implementar  prometheus en nuestro cluster. Para esto vamos a utilizar el arhivo prometheus-deployment.yaml alojado en la url:

[https://github.com/mercadoalex/Monitoring-Kubernetes-Cluster/blob/main/Prometheus-Grafana/prometheus.deployment.yml](URL)

Dicho archivo contiene :

- servicio
- deployment
- clusterRole
- clusterRoleBinding
- configmaps

Vamos a crear el namespace monitoring con el comando:

```bash
 kubectl create namespace monitoring```bash
```

A continuacion ingresamos al namespace creado:

```bash
kubectl config set-context --current --namespace=monitoring
```

Una vez dentro del namespace comenzamos modificamos el    svc (servicio) de nuestro archivo prometheus.deployment.yml para que tenga el type LoadBalancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring
  annotations:  
      prometheus.io/scrape: 'true'     
      prometheus.io/port:   '9090'
spec:
  selector: 
    app: prometheus-server
  type: LoadBalancer  
  ports:
    - port: 9090
      targetPort: 9090 
      nodePort: 30000
```

Luego  aplicamos el archivo prometheus.deployment.yml con el comando:

```bash
kubectl apply -f  prometheus.deployment.yml
```

Verificamos que el status del pod de prometheus server:

```bash
jlb@haproxy:~/monitoreo$ kubectl get po
NAME                                     READY   STATUS    RESTARTS   AGE
prometheus-deployment-556fbcc476-flrk7   1/1     Running   0          5s
```

Probamos ingreasar a prometheus via browser:

[http://10.10.100.35:9090/](URL)



### Deploy de node-exporter

Con motivo de poder tener metricas de los nodos  k8s, a saber uso de CPU, RAM, red, etc, necesitamos deployar pods de node-exporter en cada uno de los nodos. En este caso utilizaremos helm para realizar el deploy mencioando con los siguintes comandos:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-node-exporter prometheus-community/prometheus-node-exporter --namespace monitoring
```

Ahora comprobamos el status de los pods de node-exporter:

```bash
jlb@haproxy:~/monitoreo$ kubectl get po
NAME                                     READY   STATUS    RESTARTS   AGE
prometheus-node-exporter-f88b5           1/1     Running   0          2s
prometheus-node-exporter-gvwsj           1/1     Running   0          2s
prometheus-node-exporter-jklvz           1/1     Running   0          2s
prometheus-node-exporter-l7f2f           1/1     Running   0          2s
prometheus-node-exporter-n4rcn           1/1     Running   0          2s
prometheus-node-exporter-r55g2           1/1     Running   0          2s
```

