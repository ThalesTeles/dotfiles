#!/bin/bash

while true; do
    # Pega a porcentagem da bateria (BAT0 ou BAT1, verifique com 'ls /sys/class/power_supply/')
    BAT=$(cat /sys/class/power_supply/BAT*/capacity | head -n 1)
    STATUS=$(cat /sys/class/power_supply/BAT*/status | head -n 1)

    # Se estiver descarregando e a bateria for menor ou igual a 35%
    if [[ "$STATUS" == "Discharging" && "$BAT" -le 35 ]]; then
        notify-send -u critical "⚠️ Bateria Fraca" "Nível em ${BAT}% - Conecte o carregador!"
        sleep 180 # Espera 3 min para não spammar notificação
    else
        sleep 60 # Verifica a cada 1 minuto
    fi
done
