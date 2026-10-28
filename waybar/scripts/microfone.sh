#!/bin/bash
# Ícone do microfone (custom/microfone): mudo, ligado sem uso ou em uso por algum app.
# Fica rodando e reimprime o JSON a cada evento do PipeWire (pactl subscribe), sem polling.

# Apps que abrem o microfone só para medir nível (não contam como "em uso")
IGNORAR='^(PulseAudio Volume Control|pavucontrol|cava|waybar)$'

imprimir() {
    local fonte desc vol mudo apps
    fonte=$(pactl get-default-source)
    desc=$(pactl -f json list sources | jq -r --arg n "$fonte" '.[] | select(.name == $n) | .description')
    vol=$(pactl get-source-volume "$fonte" | grep -oE '[0-9]+%' | head -n 1)
    mudo=$(pactl get-source-mute "$fonte" | awk '{print $2}')

    # Gravações ativas, sem contar as que escutam um monitor (saída de áudio)
    apps=$(pactl -f json list source-outputs | jq -r --arg ign "$IGNORAR" '
        .[] | select(.properties["stream.monitor"] != "true")
            | .properties["application.name"] // .properties["application.process.binary"] // "desconhecido"
            | select(test($ign) | not)' | sort -u | paste -sd ',' | sed 's/,/, /g')

    local icone classe tooltip
    if [[ "$mudo" == yes ]]; then
        icone="󰍭" classe="mudo" tooltip="Microfone mudo"
    elif [[ -n "$apps" ]]; then
        icone="󰍬" classe="em-uso" tooltip="Microfone em uso por: $apps"
    else
        icone="󰍬" classe="livre" tooltip="Microfone ligado, sem uso no momento"
    fi
    tooltip+="\n$desc · $vol\nClique: mudo · Rolar: volume · Direito: pavucontrol"

    printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' "$icone" "$classe" "$tooltip"
}

imprimir
pactl subscribe | grep --line-buffered -E "'(change|new|remove)' on (source|source-output|server)" | while read -r _; do
    imprimir
done
