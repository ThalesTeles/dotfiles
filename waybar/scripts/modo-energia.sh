#!/bin/bash
# Ícone e tooltip do modo de energia (custom/modo-energia).
# Atualiza a cada 10 s e na hora em que o modo muda (o modo-energia.sh do hypr envia o sinal RTMIN+8).

modo=$(cat "$HOME/.local/state/modo-energia/modo" 2>/dev/null || echo auto)
cpu=/sys/devices/system/cpu/cpu0/cpufreq

case "$modo" in
performance) icone="󰓅" nome="Performance" ;;
economia) icone="󰌪" nome="Economia" ;;
*) icone="󰁪" nome="Automático" modo=auto ;;
esac

# Estado real da CPU agora (no automático muda com a tomada)
governor=$(cat "$cpu/scaling_governor")
max_ghz=$(awk '{printf "%.1f", $1 / 1000000}' "$cpu/scaling_max_freq" | tr . ,)
[[ "$(cat /sys/devices/system/cpu/cpufreq/boost)" == 1 ]] && turbo="ligado" || turbo="desligado"

tooltip="Modo $nome\nCPU: $governor · até $max_ghz GHz · turbo $turbo"
[[ "$modo" == economia ]] && tooltip+="\nBrilho limitado a 40% · sem blur e animações"
tooltip+="\nClique para trocar o modo"

echo "{\"text\": \"$icone\", \"class\": \"$modo\", \"tooltip\": \"$tooltip\"}"
