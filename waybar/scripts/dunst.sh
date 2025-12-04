#!/bin/bash

count=$(dunstctl count waiting)

# 1. Defina os padrões iniciais aqui para evitar que fiquem vazios
enabled=""
disabled=""

# 2. Adiciona o contador ao ícone APENAS se houver notificações
if [ "$count" != "0" ]; then
    enabled=" $count"
    disabled=" $count"
fi

# 3. Verifica o status e imprime o JSON
if dunstctl is-paused | grep -q "false"; then
    echo "{\"text\": \"$enabled\", \"class\": \"enabled\", \"tooltip\": \"Notificações Ativadas ($count aguardando)\"}"
else
    echo "{\"text\": \"$disabled\", \"class\": \"disabled\", \"tooltip\": \"Não Perturbe (DND)\"}"
fi
