#!/bin/bash

# Script para asignar IPs de MetalLB al nodo local
# Autor: Jose Luis (vRack Demencial Mode)

# Configurá el namespace donde está MetalLB
METALLB_NS="metallb-system"

# Detectar hostname del nodo actual
NODO=$(hostname)

# Detectar interfaz LAN principal automáticamente (podés fijarla a mano si preferís)
INTERFAZ=$(ip route get 8.8.8.8 | awk -- '{ print $5; exit }')

echo "[INFO] Nodo actual: $NODO"
echo "[INFO] Interfaz LAN detectada: $INTERFAZ"

# Obtener todas las IPs asignadas por MetalLB
IPS=$(kubectl get svc -A -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.status.loadBalancer.ingress[0].ip}{"\n"}{end}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

for ip in $IPS; do
    # Verificamos si ya está asignada
    if ip a show dev "$INTERFAZ" | grep -q "$ip"; then
        echo "[OK] IP $ip ya está asignada en $INTERFAZ"
    else
        echo "[+] Asignando IP $ip a $INTERFAZ"
        sudo ip addr add "$ip/32" dev "$INTERFAZ"
    fi
done

echo "[✅] Listo. Todas las IPs de MetalLB asignadas."
