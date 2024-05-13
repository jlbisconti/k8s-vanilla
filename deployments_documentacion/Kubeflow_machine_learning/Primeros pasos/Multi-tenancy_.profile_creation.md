# Kubeflow Multi-Tenancy

Kubeflow multi-tenancy es la capacidad de  Kubeflow para  aislar a múltiples usuarios independientes o equipos. En una implementación de Kubeflow de múltiples tenants, cada tenant tiene sus propios recursos dedicados y puede acceder y usar la plataforma Kubeflow sin interferir con otros tenants . Kubeflow admite multi-tenancy utilizando espacios de nombres en Kubernetes. Cada tenant  tiene un espacio de nombres dedicado, que proporciona un aislamiento lógico de los recursos.

## Profiles de Kubeflow

Profile de Kubeflow: Un profile en Kubeflow es similar al namespace en Kubernetes,  es una configuración única para un tenant  que determina sus privilegios de acceso y está definido por el Administrador.

Para ver los perfiles existentes en el clúster, utilizamos el  siguiente comando:

```
kubectl get profiles
```

En nuestro caso vamos a ver que por el momento solo tenemos el profile generado durante el deploy de kubeflow:

```bash
jlb@lb-vmware:~/kubeflow-files$ kubectl get profiles
NAME                        AGE
kubeflow-user-example-com   20h
```

## Creacion de profile

Como indique anteriormente en Kubeflow el profile es analogo al namespace en k8s. A continuacion voy a crear un profile creando el sigiente archivo al que llame profile-jlb.yaml:

```yaml
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: kubeflow-jlb-gsve-com   # El nombre del profile tiene que contener el nombre del usario y del dominio que vamos a utilizar
spec:
  owner:
    kind: User
    name: jlb@gsve.com   

  resourceQuotaSpec:    # resource quota es opcional
   hard:
     cpu: "2"
     memory: 2Gi
     requests.amd.com/gpu: "1"
     persistentvolumeclaims: "1"
     requests.storage: "5Gi"
```

Luego, como  siguiente paso,  voy a crear el archivo  profile-jlb.yaml con el comando

```bash
 kubectl apply -f profile-jlb.yaml
 ```

## Creacion de las credenciales  de acceso al profile/namespace creado

En Kubeflow un usuario  tiene acceso a algún conjunto de recursos (profiles) en el clúster. Kubeflow utiliza Dex como una forma de administrar usuarios y autenticación para la plataforma. Dex es un servicio de identidad que utiliza OpenID connect para la autenticación de unidades para otras aplicaciones, y viene preconfigurado con la instalación de Kubeflow. Como parte de la instalación de Kubeflow, se crea un perfil de Kubeflow (kubeflow-user-example-com) con el usuario predeterminado (<user@example.com>).

Para comprobar los Usuarios registrados en Dex voy a utilizar el comando:

```bash
kubectl get configmap dex -n auth -o jsonpath='{.data.config\.yaml}' >dex-yaml.yaml
vim dex-yaml.yaml
 ```

Luego de la ejecucion del comando anterior nos abrira el archivo dex-yaml.yaml que contiene el configmap actual del usuario <user@example.com>.

```yaml
issuer: http://dex.auth.svc.cluster.local:5556/dex
storage:
  type: kubernetes
  config:
    inCluster: true
web:
  http: 0.0.0.0:5556
logger:
  level: "debug"
  format: text
oauth2:
  skipApprovalScreen: true
enablePasswordDB: true
staticPasswords:
- email: user@example.com
  hashFromEnv: DEX_USER_PASSWORD
  username: user
  userID: "15841185641784"
staticClients:
# https://github.com/dexidp/dex/pull/1664
- idEnv: OIDC_CLIENT_ID
  redirectURIs: ["/oauth2/callback"]
  name: 'Dex Login Application'
  secretEnv: OIDC_CLIENT_SECRET
  ```

  A  continuacion modificamos nuestro archivo dex-yaml.yaml agregando nuestro usuario:

  ```yaml
  
  issuer: http://dex.auth.svc.cluster.local:5556/dex
storage:
  type: kubernetes
  config:
    inCluster: true
web:
  http: 0.0.0.0:5556
logger:
  level: "debug"
  format: text
oauth2:
  skipApprovalScreen: true
enablePasswordDB: true
staticPasswords:
- email: user@example.com
  hashFromEnv: DEX_USER_PASSWORD
  username: user
  userID: "15841185641784"
- email: jlb@gsve.com
  hash: $2y$10$4pCIJTHKJRGhOH2WXNyKLu48PGJVSLD6FfSJDyI/QShqFofWKeLtm # En este campo coloque el hash en bcrypt de mi contraseña
  username: jlb
staticClients:
# https://github.com/dexidp/dex/pull/1664
- idEnv: OIDC_CLIENT_ID
  redirectURIs: ["/oauth2/callback"]
  name: 'Dex Login Application'
  secretEnv: OIDC_CLIENT_SECRET
  ```

En cuanto al hash bcrypt lo podemos generar por ejemplo desde la url:

[https://bcrypt.online/](URL)

Luego de guardar los cambios en el archivo dex-yaml.yaml, se puede aplicar al clúster utilizando el siguiente comando:

```bash
kubectl crea configmap dex --from-file = config.yaml =dex-yaml.yaml -n auth \
--dry-run = client -o yaml | kubectl apply -f -
```

Después de aplicar el configmap, reinicie la aplicación Dex para configurar los nuevos usuarios utilizando el siguiente comando:
 
```bash
kubectl rollout restart deployment dex -n auth
```
## Comprobacion final
Como paso final vamos a probar el login en el Kubeflow central dashboard . a travez de dex, con las credenciales agregadas en el configmap editado.

Ingresamos a la gui en nuestro browser 


![kubeflow-central-dashboard-profile-gsve-login](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/b0dc1521-ae09-40ef-ba70-0d793bb63c92)

Podemos comprobar que las credenciales funcionan y ademas ingresamos a nuestro profiles/namespace como lo muestra la siguinte imagen:


![kubeflow-central-dashboard-profile-gsve-adentro](https://github.com/jlbisconti/k8s-vanilla/assets/144631732/3722fe8d-2ad5-4e4d-bffe-7fac7c96bce5)

Hasta la proxima!!!!


