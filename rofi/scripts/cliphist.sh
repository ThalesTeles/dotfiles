#!/usr/bin/env bash

THEME_FILE="~/.config/rofi/launchers/type-1/style-5.rasi" 
FONT_SIZE="JetBrainsMono Nerd Font 18"                    
WINDOW_WIDTH="50%"                                        
WINDOW_HEIGHT="60%"                                       


# 1: true, 0: false
SHOW_ID=${1:-0} 

if [ "$SHOW_ID" -eq 1 ]; then
    DISPLAY_FLAG=""
    NEXT_STATE=0
    PROMPT_TEXT="Clipboard IDs On"
    TOGGLE_MSG="Ocultando IDs"
else
    # Padrão
    DISPLAY_FLAG="-display-columns 2"
    NEXT_STATE=1
    PROMPT_TEXT="Clipboard"
    TOGGLE_MSG="Mostrando IDs"
fi

OVERRIDE_THEME="
    window { width: ${WINDOW_WIDTH}; height: ${WINDOW_HEIGHT}; }
    * { font: \"${FONT_SIZE}\"; }
    element-text { vertical-align: 0.5; }
    element-icon { size: 32px; }
"

while true; do
    # Alt+Delete Deletar Item
    # Alt+i      Alternar IDs (Toggle)
    
    OUTPUT=$(cliphist list | rofi -dmenu \
        -theme "$THEME_FILE" \
        -theme-str "$OVERRIDE_THEME" \
        -p "$PROMPT_TEXT" \
        $DISPLAY_FLAG \
        -kb-custom-1 "Alt+Delete" \
        -kb-custom-2 "Alt+i")

    EXIT_CODE=$?

    case $EXIT_CODE in
        0) # Enter: Copiar
            if [ -n "$OUTPUT" ]; then
                echo "$OUTPUT" | cliphist decode | wl-copy
            fi
            break
            ;;
            
        10) # Alt+Delete: Apagar Item
            if [ -n "$OUTPUT" ]; then
                echo "$OUTPUT" | cliphist delete
                # O loop reinicia, atualizando a lista
            fi
            ;;
            
        11) # Alt+i: Alternar visualização de IDs
            # Reinicia o script com o novo estado (0 ou 1)
            "$0" "$NEXT_STATE"
            exit 0
            ;;
            
        *) # Esc ou Erro: Sair
            break
            ;;
    esac
done