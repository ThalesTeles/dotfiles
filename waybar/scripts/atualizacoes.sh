#!/bin/bash
# Atualizações pendentes (custom/atualizacoes): só aparece a partir de LIMITE pacotes.
# Confere a cada hora e na hora em que o yay termina (sinal RTMIN+9).

LIMITE=10

repo=$(checkupdates 2>/dev/null | wc -l)
aur=$(yay -Qua 2>/dev/null | wc -l)
total=$((repo + aur))

if ((total < LIMITE)); then
    echo '{"text": ""}'
    exit 0
fi

tooltip="$total atualizações · $repo dos repositórios, $aur do AUR\nClique: atualizar com yay · Direito: conferir de novo"
echo "{\"text\": \"󰚰 $total\", \"class\": \"pendentes\", \"tooltip\": \"$tooltip\"}"
