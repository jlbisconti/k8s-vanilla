#!/bin/bash

LOGFILE="/var/log/k8s-cert-renew.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ADMIN_CONF="/etc/kubernetes/admin.conf"
USER_HOME="/home/jlb"
USER_CONF="$USER_HOME/.kube/config"
TELEGRAM_TOKEN="7893384536:AAHa-LQpW73QVyXM9UVk_mee-r9RBaZgvEY"
CHAT_ID="2135636660"
MSG_ALERT="🚨 [K8s] Certificados del clúster fueron renovados automáticamente en $(hostname) a las $TIMESTAMP."

echo "[$TIMESTAMP] Verificando certificados..." >> "$LOGFILE"

/usr/bin/kubeadm certs check-expiration | grep "EXPIRES" -A 20 >> "$LOGFILE"

/usr/bin/kubeadm certs check-expiration | grep -q "RESIDUAL TIME.*[0-2][0-9]d" && {
    echo "[$TIMESTAMP] Certificados cerca de expirar, renovando..." >> "$LOGFILE"
    /usr/bin/kubeadm certs renew all >> "$LOGFILE" 2>&1

    echo "[$TIMESTAMP] Reiniciando kubelet..." >> "$LOGFILE"
    systemctl restart kubelet >> "$LOGFILE" 2>&1

    echo "[$TIMESTAMP] Copiando admin.conf para el usuario jlb..." >> "$LOGFILE"
    mkdir -p "$USER_HOME/.kube"
    cp "$ADMIN_CONF" "$USER_CONF"
    chown jlb:jlb "$USER_CONF"

    echo "[$TIMESTAMP] Enviando alerta por Telegram..." >> "$LOGFILE"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" \
         -d text="$MSG_ALERT" >> "$LOGFILE" 2>&1

    echo "[$TIMESTAMP] Proceso completo ✅" >> "$LOGFILE"
}


