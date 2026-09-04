#!/bin/bash

echo "Iniciando backup da infraestrutura..."

# 1. Abordagem Dinâmica: Atualiza o que pertence ao ~/.config
echo "[1/3] Sincronizando diretórios do ~/.config..."
for item in *; do
    # Verifica se o item existe no ~/.config antes de tentar copiar
    if [ -e "$HOME/.config/$item" ]; then
        cp -r "$HOME/.config/$item" ./
        echo "  -> $item atualizado."
    fi
done

# 2. Abordagem Explícita: Atualiza arquivos ocultos da raiz ~/
echo "[2/3] Sincronizando arquivos ocultos explícitos..."
cp ~/.bashrc ~/.vimrc ./
echo "  -> .bashrc e .vimrc atualizados."

# 3. Engenharia de Pacotes: Listas do Pacman e Yay (AUR)
# Flags: Q (Query), q (quiet/só nomes), e (explicitamente instalados)
# n (native/repositórios oficiais), m (foreign/AUR)
echo "[3/3] Gerando listas de pacotes (Repositórios e AUR)..."
pacman -Qqen > pkglist_repo.txt
pacman -Qqem > pkglist_aur.txt
echo "  -> pkglist_repo.txt e pkglist_aur.txt gerados."

echo "Backup concluído com sucesso. Lembre-se de rodar 'git status' e commitar as alterações."