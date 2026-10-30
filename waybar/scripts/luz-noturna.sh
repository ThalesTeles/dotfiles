#!/bin/bash
# Luz noturna (custom/luz-noturna) com o hyprsunset.
# Sem argumento imprime o JSON; "alternar", "mais-quente", "mais-fria" e "slider" mudam o estado
# e avisam a Waybar (sinal RTMIN+11). O slider é um zenity (tema GTK global do matugen). Some da barra se o hyprsunset não estiver instalado.

estado="$HOME/.local/state/luz-noturna"
mkdir -p "$estado"
temp=$(cat "$estado/temperatura" 2>/dev/null || echo 4000)
PASSO=250 MIN=2500 MAX=6000

command -v hyprsunset >/dev/null || { echo '{"text": ""}'; exit 0; }

ligada() { pgrep -x hyprsunset >/dev/null && [[ -f "$estado/ligada" ]]; }

aplicar() {
    pgrep -x hyprsunset >/dev/null || { hyprsunset >/dev/null 2>&1 & disown; sleep 0.5; }
    hyprctl hyprsunset temperature "$temp" >/dev/null
    touch "$estado/ligada"
}

case "$1" in
alternar)
    if ligada; then
        hyprctl hyprsunset identity >/dev/null
        rm -f "$estado/ligada"
    else
        aplicar
    fi
    ;;
mais-quente | mais-fria)
    [[ "$1" == mais-quente ]] && temp=$((temp - PASSO)) || temp=$((temp + PASSO))
    ((temp < MIN)) && temp=$MIN
    ((temp > MAX)) && temp=$MAX
    echo "$temp" >"$estado/temperatura"
    # Rolar já liga a luz noturna, para ver o efeito na hora
    aplicar
    ;;
slider)
    # Segundo clique com o slider aberto: fecha
    if pkill -f 'zenity --scale --title=Luz noturna'; then exit 0; fi
    anterior=$temp
    ligada && estava=1 || estava=0
    aplicar
    # Aplica ao vivo enquanto arrasta; OK salva, Cancelar volta ao que era
    zenity --scale --title="Luz noturna" --text="Temperatura (K) · menor = mais quente" \
        --min-value=$MIN --max-value=$MAX --step=100 --value="$temp" --print-partial 2>/dev/null |
        while read -r v; do
            hyprctl hyprsunset temperature "$v" >/dev/null
            echo "$v" >"$estado/temperatura"
        done
    if ((PIPESTATUS[0] != 0)); then
        echo "$anterior" >"$estado/temperatura"
        temp=$anterior
        if ((estava)); then aplicar; else hyprctl hyprsunset identity >/dev/null; rm -f "$estado/ligada"; fi
    fi
    ;;
esac

if [[ -n "$1" ]]; then
    pkill -RTMIN+11 waybar
    exit 0
fi

if ligada; then
    echo "{\"text\": \"󰖔\", \"class\": \"ligada\", \"tooltip\": \"Luz noturna ligada · ${temp} K\\nClique: desligar · Rolar: mais quente/fria · Direito: slider\"}"
else
    echo "{\"text\": \"󰖙\", \"class\": \"desligada\", \"tooltip\": \"Luz noturna desligada · ${temp} K ao ligar\\nClique: ligar · Rolar: ajustar · Direito: slider\"}"
fi
