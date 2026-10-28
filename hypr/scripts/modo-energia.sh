#!/bin/bash
# Modos de energia: performance, economia e auto.
#
#   modo-energia.sh aplicar <performance|economia|auto>  -> chamado pelo applet de bateria do rofi
#   modo-energia.sh monitor                              -> autostart: reaplica o modo e ajusta o brilho no auto
#   modo-energia.sh reaplicar                            -> reaplica a economia após "hyprctl reload" (ex.: matugen)
#   modo-energia.sh brilho <up|down>                     -> teclas de brilho (Fn+F6 / Fn+F5)
#
# Economia: CPU no perfil mais econômico (EPP power, sem turbo, máx. 1,4 GHz),
#           brilho travado em 40%, sem blur/sombra/animações e Bluetooth desligado se nada estiver conectado.
# Auto:     auto-cpufreq decide pela tomada; brilho vai a 100% na tomada e 40% na bateria (sem travar).

ESTADO="$HOME/.local/state/modo-energia"
PERFIS="/etc/auto-cpufreq-perfis" # normal.conf e economia.conf
BRILHO_ECONOMIA=40                # % do brilho máximo
NOTIF_ID=9903

mkdir -p "$ESTADO"

modo_atual() { cat "$ESTADO/modo" 2>/dev/null || echo auto; }
na_tomada() { [[ "$(cat /sys/class/power_supply/ADP*/online 2>/dev/null | head -n 1)" == 1 ]]; }
brilho_pct() { echo $(($(brightnessctl get) * 100 / $(brightnessctl max))); }

# $1 = override do governor (performance|powersave|reset), $2 = perfil da config (normal|economia)
cpu() {
    if ! cmp -s "$PERFIS/$2.conf" /etc/auto-cpufreq.conf; then
        sudo -n /usr/bin/cp "$PERFIS/$2.conf" /etc/auto-cpufreq.conf || return 1
    fi
    sudo -n /usr/bin/auto-cpufreq --force="$1" >/dev/null
}

# --- Efeitos do Hyprland (só em tempo de execução, a config não é alterada) ---
salvar_efeitos() {
    for opt in decoration:blur:enabled decoration:shadow:enabled animations:enabled; do
        echo "$(hyprctl getoption "$opt" | awk 'NR==1 {print $2}')"
    done >"$ESTADO/efeitos"
}

# $1 $2 $3 = blur sombra animações (true|false)
efeitos() {
    hyprctl eval "hl.config({ decoration = { blur = { enabled = $1 }, shadow = { enabled = $2 } }, animations = { enabled = $3 } })" >/dev/null
}

restaurar_efeitos() {
    local v
    mapfile -t v <"$ESTADO/efeitos" 2>/dev/null || v=(true true true)
    efeitos "${v[0]:-true}" "${v[1]:-true}" "${v[2]:-true}"
}

# --- Bluetooth ---
desligar_bluetooth() {
    bluetoothctl show | grep -q "Powered: yes" || return 0
    if [[ -n "$(bluetoothctl devices Connected)" ]]; then
        echo "Bluetooth mantido (aparelho conectado)"
        return 0
    fi
    bluetoothctl power off >/dev/null && touch "$ESTADO/bluetooth-desligado"
}

religar_bluetooth() {
    [[ -f "$ESTADO/bluetooth-desligado" ]] && bluetoothctl power on >/dev/null
    rm -f "$ESTADO/bluetooth-desligado"
}

# Atualiza os ícones de modo (custom/modo-energia) e de brilho (custom/brilho) na waybar
avisar_waybar() {
    pkill -RTMIN+8 -x waybar
    pkill -RTMIN+10 -x waybar
}

# --- Brilho ---
brilho_auto() {
    if na_tomada; then
        brightnessctl -q set 100%
    else
        brightnessctl -q set "${BRILHO_ECONOMIA}%"
    fi
    avisar_waybar
}

brilho() {
    if [[ "$1" == down ]]; then
        brightnessctl -q -e4 set 5%-
        return
    fi
    if [[ "$(modo_atual)" == economia ]]; then
        if (($(brilho_pct) >= BRILHO_ECONOMIA)); then
            dunstify -u low -r "$NOTIF_ID" "Brilho" "Limitado a ${BRILHO_ECONOMIA}% no modo Economia"
            return
        fi
        brightnessctl -q -e4 set 5%+
        (($(brilho_pct) > BRILHO_ECONOMIA)) && brightnessctl -q set "${BRILHO_ECONOMIA}%"
    else
        brightnessctl -q -e4 set 5%+
    fi
}

aplicar() {
    local anterior
    anterior="$(modo_atual)"
    case "$1" in
    economia)
        cpu powersave economia || return 1
        if [[ "$anterior" != economia ]]; then
            brightnessctl get >"$ESTADO/brilho"
            salvar_efeitos
        fi
        brightnessctl -q set "${BRILHO_ECONOMIA}%"
        efeitos false false false
        desligar_bluetooth
        ;;
    performance | auto)
        if [[ "$1" == performance ]]; then
            cpu performance normal || return 1
        else
            cpu reset normal || return 1
        fi
        if [[ "$anterior" == economia ]]; then
            restaurar_efeitos
            religar_bluetooth
        fi
        if [[ "$1" == auto ]]; then
            brilho_auto
        elif [[ "$anterior" == economia && -f "$ESTADO/brilho" ]]; then
            brightnessctl -q set "$(cat "$ESTADO/brilho")"
        fi
        ;;
    *)
        echo "Modo inválido: $1" >&2
        return 1
        ;;
    esac
    echo "$1" >"$ESTADO/modo"
}

# Após reiniciar ou recarregar o Hyprland, os efeitos voltam pela config: reaplica a economia
reaplicar() {
    [[ "$(modo_atual)" == economia ]] || return 0
    efeitos false false false
    (($(brilho_pct) > BRILHO_ECONOMIA)) && brightnessctl -q set "${BRILHO_ECONOMIA}%"
    return 0
}

monitor() {
    # Evita várias instâncias rodando ao mesmo tempo
    exec 9>"${XDG_RUNTIME_DIR:-/tmp}/modo-energia.lock"
    flock -n 9 || exit 0

    reaplicar

    local ultimo agora
    na_tomada && ultimo=1 || ultimo=0
    udevadm monitor --udev --subsystem-match=power_supply | while read -r _; do
        na_tomada && agora=1 || agora=0
        if [[ "$agora" != "$ultimo" ]]; then
            ultimo="$agora"
            [[ "$(modo_atual)" == auto ]] && brilho_auto
        fi
    done
}

case "$1" in
aplicar) aplicar "$2" && avisar_waybar ;;
monitor) monitor ;;
reaplicar) reaplicar; avisar_waybar ;;
brilho) brilho "$2"; avisar_waybar ;;
*)
    echo "Uso: $0 aplicar <performance|economia|auto> | monitor | reaplicar | brilho <up|down>" >&2
    exit 1
    ;;
esac
