#!/bin/bash

# Evita várias instâncias rodando ao mesmo tempo
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/battery_notify.lock"
flock -n 9 || exit 0

LIMITE=45 # abaixo disso: aviso de bateria + modo economia
NOTIF_ID=9901 # ID fixo: cada notificação nova substitui a anterior
ECON_ID=9902  # aviso de saída do modo economia
ULTIMO=""
ECONOMIA=""

# Modo economia: corta efeitos do Hyprland e desliga o turbo da CPU.
# O turbo só muda se a regra de sudo (auto-cpufreq-turbo.sudoers) estiver instalada.
economia_on() {
    hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false } } })' >/dev/null
    sudo -n /usr/bin/auto-cpufreq --turbo never >/dev/null 2>&1
}

economia_off() {
    hyprctl eval 'hl.config({ animations = { enabled = true }, decoration = { blur = { enabled = true }, shadow = { enabled = true } } })' >/dev/null
    sudo -n /usr/bin/auto-cpufreq --turbo auto >/dev/null 2>&1
}

while true; do
    BAT=$(cat /sys/class/power_supply/BAT*/capacity | head -n 1)
    STATUS=$(cat /sys/class/power_supply/BAT*/status | head -n 1)

    # Se estiver descarregando e a bateria for menor ou igual ao limite
    if [[ "$STATUS" == "Discharging" && "$BAT" -le $LIMITE ]]; then
        # Só notifica quando a porcentagem muda
        if [[ "$BAT" != "$ULTIMO" ]]; then
            # Reaplica a cada mudança: um reload do Hyprland religaria os efeitos
            economia_on
            ECONOMIA=1
            dunstify -u critical -r "$NOTIF_ID" -i battery-caution-symbolic "Bateria ${BAT}%" "Conecte o carregador"$'\n'"Modo economia ativo"
            ULTIMO="$BAT"
        fi
    elif [[ -n "$ULTIMO" ]]; then
        # Carregador conectado (ou bateria acima do limite): remove o aviso
        dunstify -C "$NOTIF_ID"
        ULTIMO=""
        if [[ -n "$ECONOMIA" ]]; then
            economia_off
            ECONOMIA=""
            dunstify -u low -r "$ECON_ID" -i battery-good-charging-symbolic "Modo economia desativado" "Efeitos e turbo restaurados"
        fi
    fi
    sleep 30
done
