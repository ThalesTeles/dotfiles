#!/bin/bash

echo "Iniciando backup da infraestrutura..."

# 1. Abordagem Dinâmica: Atualiza o que pertence ao ~/.config
echo "[1/5] Sincronizando diretórios do ~/.config..."
for item in *; do
    # Verifica se o item existe no ~/.config antes de tentar copiar
    if [ -e "$HOME/.config/$item" ]; then
        cp -r "$HOME/.config/$item" ./
        echo "  -> $item atualizado."
    fi
done

# 2. Abordagem Explícita: Atualiza arquivos ocultos da raiz ~/
echo "[2/5] Sincronizando arquivos ocultos explícitos..."
cp ~/.bashrc ~/.inputrc ~/.vimrc ~/.latexmkrc ./
echo "  -> .bashrc, .inputrc, .vimrc e .latexmkrc atualizados."

# 3. Arquivos de sistema em /etc (espelhados em ./etc com o mesmo caminho)
echo "[3/5] Sincronizando arquivos de sistema do /etc..."
ETC_FILES=(
    /etc/auto-cpufreq-perfis/normal.conf
    /etc/auto-cpufreq-perfis/economia.conf
    /etc/modprobe.d/v4l2loopback.conf
    /etc/modules-load.d/v4l2loopback.conf
    /etc/sudoers.d/auto-cpufreq
)
for file in "${ETC_FILES[@]}"; do
    mkdir -p ".$(dirname "$file")"
    if [ -r "$file" ]; then
        cp "$file" ".$file"
    else
        # Arquivos só legíveis pelo root (ex.: sudoers.d) pedem a senha
        # (via arquivo temporário para não apagar a cópia do repo se falhar)
        tmp=$(mktemp)
        if ! sudo cat "$file" > "$tmp"; then
            rm -f "$tmp"
            echo "  -> falha ao ler $file (cópia do repo mantida)"
            continue
        fi
        mv "$tmp" ".$file"
    fi
    echo "  -> $file atualizado."
done

# 4. Engenharia de Pacotes: Listas do Pacman e Yay (AUR)
# Flags: Q (Query), q (quiet/só nomes), e (explicitamente instalados)
# n (native/repositórios oficiais), m (foreign/AUR)
echo "[4/5] Gerando listas de pacotes (Repositórios e AUR)..."
pacman -Qqen > pkglist_repo.txt
pacman -Qqem > pkglist_aur.txt
echo "  -> pkglist_repo.txt e pkglist_aur.txt gerados."

# 5. Serviços habilitados no systemd (sistema e usuário)
echo "[5/5] Salvando listas de serviços habilitados..."
systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' > services_system.txt
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' > services_user.txt
echo "  -> services_system.txt e services_user.txt gerados."

echo "Backup concluído com sucesso. Lembre-se de rodar 'git status' e commitar as alterações."