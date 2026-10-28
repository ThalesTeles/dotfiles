#!/bin/bash

# Evita várias instâncias rodando ao mesmo tempo
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/battery_notify.lock"
flock -n 9 || exit 0

LIMITE=35
NOTIF_ID=9901 # ID fixo: cada notificação nova substitui a anterior
ULTIMO=""

while true; do
    BAT=$(cat /sys/class/power_supply/BAT*/capacity | head -n 1)
    STATUS=$(cat /sys/class/power_supply/BAT*/status | head -n 1)

    # Se estiver descarregando e a bateria for menor ou igual ao limite
    if [[ "$STATUS" == "Discharging" && "$BAT" -le $LIMITE ]]; then
        # Só notifica quando a porcentagem muda
        if [[ "$BAT" != "$ULTIMO" ]]; then
            dunstify -u critical -r "$NOTIF_ID" -i battery-caution-symbolic "Bateria ${BAT}%" "Conecte o carregador"
            ULTIMO="$BAT"
        fi
    elif [[ -n "$ULTIMO" ]]; then
        # Carregador conectado (ou bateria acima do limite): remove o aviso
        dunstify -C "$NOTIF_ID"
        ULTIMO=""
    fi
    sleep 30
done
