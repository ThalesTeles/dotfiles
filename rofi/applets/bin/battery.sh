#!/usr/bin/env bash

## Configurações Visuais
DIR="$HOME/.config/rofi/launchers/type-1"
THEME="style-5"

## 1. Coleta de Dados
BAT_PERC=$(cat /sys/class/power_supply/BAT*/capacity | head -n 1)
BAT_STATUS=$(cat /sys/class/power_supply/BAT*/status | head -n 1)

# Ícones do Cabeçalho (Nerd Font)
if [[ "$BAT_STATUS" == "Charging" ]]; then
  ICON=""
elif [[ "$BAT_PERC" -ge 98 ]]; then
  ICON=""
elif [[ "$BAT_PERC" -ge 75 ]]; then
  ICON=""
elif [[ "$BAT_PERC" -ge 50 ]]; then
  ICON=""
elif [[ "$BAT_PERC" -ge 25 ]]; then
  ICON=""
else
  ICON=""
fi
## 2. Tempo Restante e Status (Por Extenso)
# Captura o tempo bruto (ex: 05:30)
RAW_TIME=$(acpi -b | grep -oE '[0-9]{2}:[0-9]{2}' | head -n 1)

if [[ "$BAT_STATUS" == "Charging" ]]; then
  TIME_MSG="⚡ Carregando..."
elif [[ "$BAT_STATUS" == "Full" ]] || [[ "$BAT_PERC" -eq 100 ]]; then
  TIME_MSG="Carga Completa"
else
  if [ -n "$RAW_TIME" ]; then
    # Separa horas e minutos
    IFS=: read -r HRS MIN <<<"$RAW_TIME"

    # Remove zero à esquerda (transforma 05 em 5) para não dar erro matemático
    HRS=$((10#$HRS))
    MIN=$((10#$MIN))

    # Monta a frase gramaticalmente correta
    if [ "$HRS" -gt 0 ] && [ "$MIN" -gt 0 ]; then
      TIME_MSG=" $HRS horas e $MIN minutos"
    elif [ "$HRS" -gt 0 ]; then
      TIME_MSG=" $HRS horas restantes"
    else
      TIME_MSG=" $MIN minutos restantes"
    fi
  else
    TIME_MSG="Carregando..."
  fi
fi
## 3. Opções (Ícones Monocromáticos + Texto)
PERF="   Performance"
SAVE="   Economia"
AUTO="   Automático"

## 4. Rofi
# Alterações importantes:
# - window height: Aumentado para 360px para caber tudo sem scroll.
# - listview: fixed-height: false garante que ele use o espaço necessário.
run_rofi() {
  echo -e "$PERF\n$SAVE\n$AUTO" | rofi \
    -dmenu \
    -p "$ICON  $BAT_PERC%" \
    -mesg "$TIME_MSG" \
    -theme ${DIR}/${THEME}.rasi \
    -theme-str "window { width: 400px; height: 380px; }" \
    -theme-str 'listview { lines: 3; fixed-height: false; scrollbar: false; }' \
    -theme-str 'inputbar { children: [prompt]; }' \
    -theme-str 'prompt { font: "JetBrainsMono Nerd Font Bold 24"; margin: 0 0 10px 0; horizontal-align: 0.5; }' \
    -theme-str 'textbox { font: "JetBrainsMono Nerd Font 16"; horizontal-align: 0.5; margin: 0 0 20px 0; text-color: @foreground; }' \
    -theme-str 'element-text { horizontal-align: 0.0; margin: 5px 0 5px 20px; }'
}

## 5. Execução
CHOSEN="$(run_rofi)"

# Troca o modo sem pedir senha (regras NOPASSWD em /etc/sudoers.d/auto-cpufreq)
set_mode() {
  local saida
  if saida=$(~/.config/hypr/scripts/modo-energia.sh aplicar "$1"); then
    dunstify -u "$2" -r 9902 "Bateria" "$3${saida:+\n$saida}"
  else
    dunstify -u critical -r 9902 "Bateria" "Falha ao trocar o modo (sudo sem senha não configurado?)"
  fi
}

case ${CHOSEN} in
"$PERF") set_mode performance normal " Modo Performance Ativado" ;;
"$SAVE") set_mode economia low "  Modo Economia Ativado" ;;
"$AUTO") set_mode auto normal "  Modo Automático Ativado" ;;
esac
