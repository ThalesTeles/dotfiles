#!/bin/bash
# Aviso de bateria fraca + troca automática para o modo Economia (via modo-energia.sh).
# Abaixo do LIMITE, descarregando: muda para Economia. Avisos de bateria só nos
# NIVEIS, uma vez cada por descarga (a porcentagem baixa já aparece na Waybar). Na tomada: volta ao modo de antes.

# Evita várias instâncias rodando ao mesmo tempo
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/battery_notify.lock"
flock -n 9 || exit 0

LIMITE=45          # abaixo disso: modo Economia
NIVEIS=(45 30 15 5) # avisos de bateria (45 = entrada no modo Economia)
AVISADO=101        # menor nível já avisado nesta descarga
NOTIF_ID=9901 # ID fixo: cada notificação nova substitui a anterior
ECON_ID=9902  # aviso de volta ao modo anterior
MODO_ENERGIA="$HOME/.config/hypr/scripts/modo-energia.sh"
ESTADO="$HOME/.local/state/modo-energia"
ANTES="$ESTADO/modo-antes-bateria" # existe enquanto a troca automática estiver valendo

modo_atual() { cat "$ESTADO/modo" 2>/dev/null || echo auto; }

nome_modo() {
    case "$1" in
    performance) echo "Performance" ;;
    economia) echo "Economia" ;;
    *) echo "Automático" ;;
    esac
}

# Eventos de energia (plugar/desplugar, mudança de carga) acordam o loop na hora
# 9>&-: o udevadm não herda a trava (senão ela fica presa se o script morrer)
coproc EVENTOS { exec udevadm monitor --udev --subsystem-match=power_supply 9>&-; }

while true; do
    BAT=$(cat /sys/class/power_supply/BAT*/capacity | head -n 1)
    STATUS=$(cat /sys/class/power_supply/BAT*/status | head -n 1)

    # Se estiver descarregando e a bateria for menor ou igual ao limite
    if [[ "$STATUS" == "Discharging" && "$BAT" -le $LIMITE ]]; then
        # Troca uma vez por descarga; se depois você mudar o modo na mão, ele é respeitado
        if [[ ! -f "$ANTES" ]]; then
            modo_atual >"$ANTES"
            [[ "$(modo_atual)" != economia ]] && "$MODO_ENERGIA" aplicar economia
        fi
        # Um reload do Hyprland religa os efeitos: reaplica a economia
        if [[ "$(modo_atual)" == economia && "$(hyprctl getoption animations:enabled)" == *"bool: true"* ]]; then
            "$MODO_ENERGIA" reaplicar
        fi
        # Avisa só ao cruzar um dos NIVEIS (o menor cruzado, se pulou mais de um)
        nivel=""
        for n in "${NIVEIS[@]}"; do
            ((BAT <= n && n < AVISADO)) && nivel=$n
        done
        if [[ -n "$nivel" ]]; then
            ((nivel <= 15)) && urgencia=critical || urgencia=normal
            dunstify -u "$urgencia" -r "$NOTIF_ID" -i battery-caution-symbolic "Bateria ${BAT}%" "Conecte o carregador"$'\n'"Modo $(nome_modo "$(modo_atual)")"
            AVISADO=$nivel
        fi
    else
        AVISADO=101
    fi

    if [[ ! ("$STATUS" == "Discharging" && "$BAT" -le $LIMITE) && -f "$ANTES" ]]; then
        # Carregador conectado (ou bateria acima do limite): remove o aviso e volta ao modo de antes
        dunstify -C "$NOTIF_ID"
        anterior=$(cat "$ANTES")
        rm -f "$ANTES"
        if [[ "$(modo_atual)" == economia && "$anterior" != economia ]]; then
            "$MODO_ENERGIA" aplicar "$anterior"
            dunstify -u low -r "$ECON_ID" -i battery-good-charging-symbolic "Modo $(nome_modo "$anterior")" "Economia desativada no carregador"
        fi
    fi

    # Espera um evento de energia (no máximo 30s); depois descarta a rajada de eventos
    read -r -t 30 -u "${EVENTOS[0]}" _
    sleep 1
    while read -r -t 0.2 -u "${EVENTOS[0]}" _; do :; done
done
