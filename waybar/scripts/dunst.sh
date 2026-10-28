#!/bin/bash
# Ícone do dunst (custom/dunst): ativado ou "não perturbe", com o número de notificações aguardando.
# Fica rodando e reimprime o JSON a cada mudança no dunst (sinal D-Bus PropertiesChanged), sem polling.

imprimir() {
    local count enabled disabled
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
        echo "{\"text\": \"$enabled\", \"class\": \"enabled\", \"tooltip\": \"Notificações ativadas\\nClique: não perturbe · Direito: reabrir última · Meio: fechar todas\"}"
    else
        echo "{\"text\": \"$disabled\", \"class\": \"disabled\", \"tooltip\": \"Não perturbe ($count aguardando)\\nClique: reativar\"}"
    fi
}

imprimir
dbus-monitor --session "type='signal',path='/org/freedesktop/Notifications',interface='org.freedesktop.DBus.Properties'" 2>/dev/null |
    grep --line-buffered "member=PropertiesChanged" | while read -r _; do
        imprimir
    done
