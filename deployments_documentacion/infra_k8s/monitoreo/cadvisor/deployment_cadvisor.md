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
```bash
NAME             READY   STATUS    RESTARTS        AGE
cadvisor-fk7l2   1/1     Running   3 (5m2s ago)    10s
cadvisor-p6skn   1/1     Running   5 (3m15s ago)   10s
cadvisor-qvqgm   1/1     Running   6 (2m39s ago)   11s
```

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

Verificamos el status del servicio con el comando:

```bash
kubectl get svc -n kube-system
```
Obtenemos la salida: 

```bash
jlb@haproxy:~$ kubectl get svc -n kube-system
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                  AGE
cadvisor             LoadBalancer   10.100.97.25    10.10.100.34   8080:31766/TCP          20s
```

Tambien podemos acceder via browser para comprobar que cadvisor este funcionando:


![cadvisor-web](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/459e0be2-f7a8-41b6-ba60-b195a63ad7e8)


## Modificacion de configmap de prometheus

Como siguiente paso al deploy de los pods de cadvisor en nuestros nodos worker vamos a modficar nuestro configmap de prometheus para que tome las metricas de cadvisor. Para  hacerto en estra oportunidad vamos a ingesar al dashboard de kubernetes ingresando tal como lo muestro en las siguientes imagenes:



![configmap1](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/3d30de78-ee13-4007-84b6-1a20cd50b1ab)

Como podemos ver desde nuestro kubernetes-dashboad ingresamos la namespace monitoring y editamos el configmap prometheus-server-conf.


![configmap2](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/c30bfed4-9716-48ed-b15b-8f7ed8cfdbfd)


Una vez dentro modificamos el job cadvisor con el agregado de la ip externa de cadvisor tal como lo muestro en la imagen anterior.

Por ultimo ejecuto el comando  para recrear el pod de promethues-server:

```bash
kubectl rollout restart -n monitoring deployment prometheus-deployment
```
Ahora resta verificar desde promethues que cadv¿isor esta arriba:


![chek-promethues](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/e55c3490-fdd7-45f3-9efe-8fe445be8624)


Nos vemos en el proximo documento!!!!.









