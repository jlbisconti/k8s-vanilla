
# Introduccion

Jupyter Notebooks es una aplicación web que permite crear y compartir documentos que contienen código en vivo, ecuaciones, visualizaciones y texto narrativo. Es una herramienta extremadamente popular en el ámbito de la ciencia de datos, la investigación científica y la educación debido a su capacidad para combinar código y documentación en un solo lugar. En este documento breve voy a describir como obtener el token de jupiter-notebooks una vez que se nos vencio el anterior.

# Pasos

A modo de obtener el token actual de jupiter-notebooks vasmos a ingresar  pod correspondiente:

```
 kubectl exec -it pod/jupyter-notebook-68979cff46-ghd9h -n jorsat-dev /bin/sh
```

Una vez dentro del pod obtenemos el token con el comando jupyter notebook list tal como lo muestro debajo:

```
jlb@haproxy:~/jupiter-notebooks$ kubectl exec -it pod/jupyter-notebook-68979cff46-ghd9h -n jorsat-dev /bin/sh
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
$ jupyter notebook list
Currently running servers:
<http://jupyter-notebook-68979cff46-ghd9h:8888/?token=dadff6c61903e32bc212c08a18f94a9396715f65bfbf05b6> :: /home/jovyan
```
 
 En la salida del comando jupyter notebook list se encuentra el token, en nuestro caso: dadff6c61903e32bc212c08a18f94a9396715f65bfbf05b6

Ese token es el que colocamos en el acceso web de jupiter notebooks.

Una alternativa  mas directa es ejecutar el comando jupyter notebook list a travez del comando kubect exec de la siguiente manera:

```
jlb@haproxy:~/jupiter-notebooks$ kubectl exec -it pod/jupyter-notebook-68979cff46-ghd9h -n jorsat-dev jupyter notebook list
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
Currently running servers:
<http://jupyter-notebook-68979cff46-ghd9h:8888/?token=dadff6c61903e32bc212c08a18f94a9396715f65bfbf05b6> :: /home/jovyan
```

Saludos!!