# Introduccion

Como parte de la solucion de monitoreo de alertas voy a deplegar alert-manager en mi cluster k8s. Mas adelante configurare alert manager para que mande alertas via gmail.

## Deploy de alert-manager 

Para comenzar vamos a ingresar al namespace monitoring creado en el documento Grafana_prometheus_node_exporter.md publicado anteriormente.

```bash
kubectl config set-context --current --namespace=monitoring
```

Una vez dentro de el namespace monitoring vamos a crear el config map necesario para alert-manager:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  config.yml: |
    global:
      resolve_timeout: 5m
    route:
      group_by: ['job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'default-receiver'
    receivers:
    - name: 'default-receiver'
      email_configs:
      - to: 'your-email@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'your-username'
        auth_password: 'your-password'
        auth_identity: ''
```

Aplicamos configmap:

```bash
kubectl apply -f alertmanager-config.yaml
```

Ahora vamos a crear el deployment aplicando el archivo deployment_alert-manager.yaml:


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      containers:
      - name: alertmanager
        image: prom/alertmanager:v0.23.0
        command:
          - "/bin/alertmanager"
          - "--config.file=/etc/alertmanager/config.yml"
          - "--storage.path=/alertmanager"
        ports:
        - containerPort: 9093
        volumeMounts:
        - name: config-volume
          mountPath: /etc/alertmanager
        - name: storage-volume
          mountPath: /alertmanager
      volumes:
      - name: config-volume
        configMap:
          name: alertmanager-config
          defaultMode: 420
      - name: storage-volume
        emptyDir: {}
```



```bash
kubectl apply -f deployment_alert-manager.yaml
```


Por ultimo creamos el servicio de tipo LoadBalancer:


```yaml
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  selector:
    app: alertmanager
  ports:
    - protocol: TCP
      port: 9093
      targetPort: 9093
  type: LoadBalancer
```
Verificamos la ip externa obtenida por aler-manager:

ype: LoadBalancer

```bash
kubectl get svc   -n monitoring
```

```txt
jlb@haproxy:~$ kubectl get svc   -n monitoring
NAME                       TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)          AGE
alertmanager               LoadBalancer   10.107.130.55    10.10.100.36   9093:32203/TCP   10s
```

Luego probamos acceder via browser a la url: 

[http://10.10.100.36:9093/#/alerts](URL)

La siguinte imagen ilustra la interfaz web de alert-manager:


![alert-manager](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/9262f731-47cc-4bfd-9c15-1af22452d667)

En la proxima entrega vamos a ver como conectar grafana con alertt-manager y enviar alertas a gmail.

