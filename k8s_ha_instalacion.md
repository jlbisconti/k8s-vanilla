# Introduccion
El presente documento busca detallar la implementacion de un cluster k8s en alta disponibilidad. Aqui veremos como instalar cada nodo del cluster y  de una blanceadora con la solucion HAproxy.

## Escenario planteado
En esta oportunidad utilice HyperV Versión: 10.0.22621.1 para correre las vms correspondientes a los nodos k8s y a la balanceadora HAproxy.
La nueva infraestructura virtual consta de :

- 3 nodo Master
- 1 nodo  worker ( por el momento)
- 1 Balancerador HAproxy
- SO Ubuntu 22.04 Server en todas las vms
