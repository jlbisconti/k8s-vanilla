# Introduccion

cAdvisor (abreviatura de contenedor Advisor) analiza y muestra el uso de recursos y los datos de rendimiento desde los contenedores en ejecución. cAdvisor ya viene preparado para publicar métricas en formato Prometheus. En este documento repaso paso a paso el deploy de cadvisor. 

## Deploy 

Para comenzar nos vamos a posicionar en el namespace kube-system con el comando:

```bash
kubectl config set-context --current --namespace=kube-system
```

Una dentro del namespace aplico el archivo cadvisor.yaml, que creara el daemonset,  con el siguiente contenido:


```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
  namespace: kube-system
  labels:
    k8s-app: cadvisor
spec:
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
    spec:
      containers:
      - name: cadvisor
        image: gcr.io/cadvisor/cadvisor:v0.47.0
        ports:
        - containerPort: 8080
          name: http
        resources:
          limits:
            cpu: 100m
            memory: 200Mi
          requests:
            cpu: 50m
            memory: 100Mi
        volumeMounts:
        - name: rootfs
          mountPath: /rootfs
          readOnly: true
        - name: var-run
          mountPath: /var/run
          readOnly: false
        - name: sys
          mountPath: /sys
          readOnly: true
        - name: docker
          mountPath: /var/lib/docker
          readOnly: true
        securityContext:
          privileged: true
      volumes:
      - name: rootfs
        hostPath:
          path: /
      - name: var-run
        hostPath:
          path: /var/run
      - name: sys
        hostPath:
          path: /sys
      - name: docker
        hostPath:
          path: /var/lib/docker
```

Aplicamos el archivo cadvisor.yaml con el comando:

```bash
kubectl apply -f cadvisor.yaml
```

Ahora verificamos el status d elos pods:

```bash
kubectl get pods -n kube-system -l name=cadvisor
```

Veremos una salida similar  la siguinte:

NAME             READY   STATUS    RESTARTS        AGE
cadvisor-fk7l2   1/1     Running   3 (5m2s ago)    10s
cadvisor-p6skn   1/1     Running   5 (3m15s ago)   10s
cadvisor-qvqgm   1/1     Running   6 (2m39s ago)   11s


Luego creo el service para darle acceso externo y lograr conectar cadvisor a prometeus. El svc a crear vava a ser el siguiente:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: cadvisor
  namespace: kube-system
spec:
  selector:
    name: cadvisor
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
    nodePort: 30001  
  type: LoadBalancer
```



## Modificacion de configmap de prometheus

Como siguinte paso al deploy de los pods de cadvisor en nuestros nodos worker vamos a modficar nuestro configmap de prometheus para que tome las metricas de cadvisor. Para  hacerto en estra oportunidad vamos a ingesar al dashboard de kubernetes 






