#!/bin/bash
# Ícone do brilho da tela (custom/brilho), com cadeado quando o modo Economia trava em 40%.
# Atualiza a cada 30 s e na hora em que o brilho muda (o modo-energia.sh do hypr envia o sinal RTMIN+10).

pct=$(($(brightnessctl get) * 100 / $(brightnessctl max)))
modo=$(cat "$HOME/.local/state/modo-energia/modo" 2>/dev/null || echo auto)

if ((pct < 34)); then
    icone="󰃞"
elif ((pct < 67)); then
    icone="󰃟"
else
    icone="󰃠"
fi

tooltip="Brilho $pct%"
classe="normal"
if [[ "$modo" == economia ]]; then
    icone+=" 󰌾"
    classe="travado"
    tooltip+=" · limitado a 40% no modo Economia"
fi
tooltip+="\nRolar: ajustar"

echo "{\"text\": \"$icone\", \"class\": \"$classe\", \"tooltip\": \"$tooltip\"}"
