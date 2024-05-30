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
 kubectl create namespace monitoring
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

> Nota: La ip para acceder a prometheus, en mi caso 10.10.100.35, la obtenemos verificando el svc creado con el comando kubectl get svc. Es la ip externa proporcionada por metallb nuestra LB interna. 

Asi podemos ver como se ve la gui de prometheus:


![gui-prometheus](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/e9663f1a-b89e-441b-9cb2-b4d3732481f8)



### Deploy de node-exporter

Con motivo de poder tener metricas de los nodos  k8s, a saber uso de CPU, RAM, red, etc, necesitamos deployar pods de node-exporter en cada uno de los nodos. En este caso utilizaremos helm para realizar el deploy mencionado con los siguintes comandos:

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

Para verificar el funcionamiento de los pods de node-exporter vamos a ejecutar el comando curl apuntando a cada uno de nuestros nodos k8s como en el siguinte caso:

```bash
 curl http://10.10.100.22:9100/metrics
```
En este caso la verificacion la realice  sobre el nodo  master-01 . Una fraccion de la salida obtenida con esta prueba fue la siguiente:

```txt
jlb@haproxy:~/monitoreo$ curl http://10.10.100.22:9100/metrics
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 2.3564e-05
go_gc_duration_seconds{quantile="0.25"} 2.7251e-05
go_gc_duration_seconds{quantile="0.5"} 2.9034e-05
go_gc_duration_seconds{quantile="0.75"} 4.1088e-05
go_gc_duration_seconds{quantile="1"} 0.000121719
go_gc_duration_seconds_sum 1.086848685
go_gc_duration_seconds_count 22971
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 8
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.22.2"} 1
```

En proximas entregas vamos a probar querys de Prometheus para hacer graficos de Grafana.
