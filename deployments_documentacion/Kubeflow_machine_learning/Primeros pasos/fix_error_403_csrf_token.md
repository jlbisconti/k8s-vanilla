# Introduccion

En el documento anterior creamos un profile y agregamos a dex las credenciales de acceso al mismo. Una vez que probamos el acceso a nuestro dahsboard de Kubeflow podemos comenzar a probar los distintos compponentes de Kubeflow tales como:

- Notebooks
- Tensorflows
- Volumes
- Pipelines
- Runs
- Artifacts

En mi caso decidi comenzar a probar con la creacion de un volumen de 1 GB. A partir de esta prueba fue que aparecio por primera vez para mi el error:

 ```txt
[403] Could not find CSRF cookie XSRF-TOKEN in the request.
<http://172.20.10.2:31174/volumes/api/namespaces/kubefiow-user-example->
com/pvcs
DISMISS
```

## Causas de este error

El error "[403] Could not find CSRF cookie XSRF-TOKEN in the request" en Kubeflow indica un problema relacionado con la validación del token CSRF (Cross-Site Request Forgery) durante una solicitud HTTP.

## Workaround utilizado

En esta oportunidad opte por un workaround aplicable a los demas compomentes de Kubeflow mencionados al comienzo de este documento. Lo que hice fue editar los distintos deployments y modificar la variable:

 ```txt
- name: APP_SECURE_COOKIES
  values: "true"
 ```

Modificandola para que quede de la siguiente forma:

 ```txt
- name: APP_SECURE_COOKIES
  values: "false"
 ```

Para realizar esta modificacion comenze por editar el deployment de jupyter con el comando:

 ```bash
kubectl edit deploy jupyter-web-app-deployment -n kubeflow
 ```
