#!/bin/bash

# Script para asignar IPs de MetalLB al nodo local y mostrar a qué pod pertenece cada IP
# Autor: Jose Luis (vRack Demencial Mode + Grafana Edition™)

METALLB_NS="metallb-system"
NODO=$(hostname)
INTERFAZ=$(ip route get 8.8.8.8 | awk -- '{ print $5; exit }')

echo "[INFO] Nodo actual: $NODO"
echo "[INFO] Interfaz LAN detectada: $INTERFAZ"
echo

# Obtener todos los servicios tipo LoadBalancer con IP y metadata
kubectl get svc -A -o json | jq -r '
  .items[] | select(.spec.type == "LoadBalancer") |
  "\(.metadata.namespace) \(.metadata.name) \(.status.loadBalancer.ingress[0].ip)"
' | while read -r NS SVC IP; do
    if [ -z "$IP" ] || [ "$IP" == "null" ]; then
        continue
    fi

    # Asignar la IP si no está
    if ip a show dev "$INTERFAZ" | grep -q "$IP"; then
        echo "[OK] IP $IP ya está asignada en $INTERFAZ"
    else
        echo "[+] Asignando IP $IP a $INTERFAZ"
        sudo ip addr add "$IP/32" dev "$INTERFAZ"
    fi

    # Mostrar info adicional
    echo "📦 IP $IP pertenece al servicio '$SVC' en el namespace '$NS'"
    # Obtener los endpoints (opcional)
    EP=$(kubectl -n "$NS" get endpoints "$SVC" -o jsonpath='{.subsets[*].addresses[*].targetRef.name}' 2>/dev/null)
    if [ -n "$EP" ]; then
        echo "    🔗 Asociado(s) al pod: $EP"
    fi
    echo
done

echo "[✅] Listo. Todas las IPs de MetalLB asignadas con sus pods."
