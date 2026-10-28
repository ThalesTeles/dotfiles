#!/bin/bash
# Restaura os dotfiles deste repositório num sistema Arch (o caminho inverso do update_dots.sh).
# Cada etapa pede confirmação. Tudo que for sobrescrito é copiado antes para ~/.dotfiles-backup/<data>/.
#
# Uso: ./restore_dots.sh          -> pergunta antes de cada etapa
#      ./restore_dots.sh --sim    -> responde "sim" para todas as etapas

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y-%m-%d_%H-%M-%S)"
TUDO_SIM=false
[[ "${1:-}" == "--sim" ]] && TUDO_SIM=true

# Itens da raiz do repo que não vão para o ~/.config
NAO_CONFIG=(etc .git .gitignore .bashrc .vimrc update_dots.sh restore_dots.sh
    pkglist_repo.txt pkglist_aur.txt services_system.txt services_user.txt)

confirmar() {
    $TUDO_SIM && return 0
    local resp
    read -rp "$1 [s/N] " resp
    [[ "$resp" =~ ^[sS]$ ]]
}

# Copia o destino atual para o backup antes de sobrescrever (sudo para caminhos do /etc)
guardar() {
    local destino="$1" sudo_cmd=""
    [[ "$destino" == /etc/* ]] && sudo_cmd="sudo"
    if $sudo_cmd test -e "$destino"; then
        mkdir -p "$BACKUP$(dirname "$destino")"
        $sudo_cmd cp -a "$destino" "$BACKUP$destino"
        [[ -n "$sudo_cmd" ]] && sudo chown -R "$USER:" "$BACKUP$destino"
    fi
}

if [[ $EUID -eq 0 ]]; then
    echo "Rode como seu usuário (sem sudo); o script pede a senha quando precisar."
    exit 1
fi
command -v pacman >/dev/null || { echo "Este script é para Arch Linux (pacman não encontrado)."; exit 1; }
cd "$REPO" || exit 1

echo "Restaurando dotfiles de $REPO"
echo "Backup do que for sobrescrito: $BACKUP"
echo

# 1. Pacotes dos repositórios oficiais
echo "[1/6] Pacotes dos repositórios oficiais ($(wc -l <pkglist_repo.txt) na lista)"
if confirmar "Instalar com pacman?"; then
    # Pacotes que não existem mais nos repositórios fariam o pacman abortar tudo
    disponiveis=$(comm -12 <(sort -u pkglist_repo.txt) <(pacman -Slq | sort -u))
    faltando=$(comm -23 <(sort -u pkglist_repo.txt) <(pacman -Slq | sort -u))
    [[ -n "$faltando" ]] && echo "  -> fora dos repositórios (ignorados): $(echo $faltando)"
    sudo pacman -Syu --needed $disponiveis
fi
echo

# 2. Pacotes do AUR
echo "[2/6] Pacotes do AUR ($(grep -vc -- '-debug$' pkglist_aur.txt) na lista, sem os *-debug)"
if confirmar "Instalar com yay?"; then
    if ! command -v yay >/dev/null; then
        echo "  -> yay não encontrado, instalando yay-bin do AUR..."
        sudo pacman -S --needed git base-devel
        tmp=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" && (cd "$tmp/yay-bin" && makepkg -si)
        rm -rf "$tmp"
    fi
    # *-debug são símbolos de depuração gerados ao compilar, não pacotes instalados de propósito
    grep -v -- '-debug$' pkglist_aur.txt | yay -S --needed -
fi
echo

# 3. ~/.config
itens=()
for item in * .[!.]*; do
    [[ -e "$item" ]] || continue
    [[ " ${NAO_CONFIG[*]} " == *" $item "* ]] && continue
    itens+=("$item")
done
echo "[3/6] Configurações do usuário em ~/.config: ${itens[*]}"
if confirmar "Copiar para ~/.config (arquivos existentes vão para o backup)?"; then
    mkdir -p "$HOME/.config"
    for item in "${itens[@]}"; do
        guardar "$HOME/.config/$item"
        cp -r "$item" "$HOME/.config/"
        echo "  -> ~/.config/$item"
    done
fi
echo

# 4. Arquivos da home
echo "[4/6] Arquivos da home: .bashrc .vimrc"
if confirmar "Copiar para ~/?"; then
    for f in .bashrc .vimrc; do
        guardar "$HOME/$f"
        cp "$f" "$HOME/$f"
        echo "  -> ~/$f"
    done
fi
echo

# 5. Arquivos de sistema em /etc
mapfile -t etc_files < <(cd etc && find . -type f | sed 's|^\.||' | sort)
echo "[5/6] Arquivos de sistema: $(printf '/etc%s ' "${etc_files[@]}")"
if confirmar "Instalar no /etc (pede a senha)?"; then
    for f in "${etc_files[@]}"; do
        destino="/etc$f"
        if [[ "$destino" == /etc/sudoers.d/* ]]; then
            # Um sudoers inválido pode travar o sudo: valida antes e instala só com 440 root:root
            if ! visudo -cf "etc$f" >/dev/null; then
                echo "  -> $destino INVÁLIDO, não instalado"
                continue
            fi
            modo=440
        else
            modo=644
        fi
        guardar "$destino"
        sudo install -D -m "$modo" -o root -g root "etc$f" "$destino"
        echo "  -> $destino ($modo)"
    done
fi
echo

# 6. Serviços e relógio
echo "[6/6] Serviços: $(wc -l <services_system.txt) do sistema e $(wc -l <services_user.txt) do usuário; relógio do hardware em UTC"
if confirmar "Habilitar os serviços e ajustar o relógio?"; then
    while read -r unit; do
        sudo systemctl enable "$unit" >/dev/null 2>&1 && echo "  -> $unit" || echo "  -> falhou: $unit (pacote ou unit ausente?)"
    done <services_system.txt
    # Recarrega para o systemd enxergar as units copiadas para ~/.config/systemd/user na etapa 3
    systemctl --user daemon-reload
    while read -r unit; do
        systemctl --user enable "$unit" >/dev/null 2>&1 && echo "  -> $unit (usuário)" || echo "  -> falhou: $unit (usuário)"
    done <services_user.txt
    sudo timedatectl set-local-rtc 0
    echo "  -> relógio do hardware em UTC"
fi
echo

[[ -d "$BACKUP" ]] && echo "Arquivos substituídos guardados em $BACKUP"
echo "Restauração concluída. Reinicie a sessão (ou o computador) para aplicar tudo."
