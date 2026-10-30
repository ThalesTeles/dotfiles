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
NAO_CONFIG=(etc .git .gitignore .bashrc .inputrc .vimrc .latexmkrc update_dots.sh restore_dots.sh
    pkglist_repo.txt pkglist_aur.txt services_system.txt services_user.txt)

# Projetos pessoais clonados do GitHub: "<usuário/repositório> <destino relativo à home>"
PROJETOS=(
    "ThalesTeles/livros-organizacao documents/estudos/faculdade/livros-organizacao"
    "ThalesTeles/automacao-mensagem-whatsapp documents/estudos/programacao/projetos/automacao-mensagem-whatsapp"
)

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
echo "[1/7] Pacotes dos repositórios oficiais ($(wc -l <pkglist_repo.txt) na lista)"
if confirmar "Instalar com pacman?"; then
    # Pacotes que não existem mais nos repositórios fariam o pacman abortar tudo
    disponiveis=$(comm -12 <(sort -u pkglist_repo.txt) <(pacman -Slq | sort -u))
    faltando=$(comm -23 <(sort -u pkglist_repo.txt) <(pacman -Slq | sort -u))
    [[ -n "$faltando" ]] && echo "  -> fora dos repositórios (ignorados): $(echo $faltando)"
    sudo pacman -Syu --needed $disponiveis
fi
echo

# 2. Pacotes do AUR
echo "[2/7] Pacotes do AUR ($(grep -vc -- '-debug$' pkglist_aur.txt) na lista, sem os *-debug)"
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
echo "[3/7] Configurações do usuário em ~/.config: ${itens[*]}"
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
echo "[4/7] Arquivos da home: .bashrc .inputrc .vimrc .latexmkrc"
if confirmar "Copiar para ~/?"; then
    for f in .bashrc .inputrc .vimrc .latexmkrc; do
        guardar "$HOME/$f"
        cp "$f" "$HOME/$f"
        echo "  -> ~/$f"
    done
fi
echo

# 5. Arquivos de sistema em /etc
mapfile -t etc_files < <(cd etc && find . -type f | sed 's|^\.||' | sort)
echo "[5/7] Arquivos de sistema: $(printf '/etc%s ' "${etc_files[@]}")"
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

# 6. Projetos pessoais (vêm antes dos serviços, que apontam para as pastas deles)
echo "[6/7] Projetos pessoais do GitHub: $(for p in "${PROJETOS[@]}"; do echo -n "${p%% *} "; done)"
if confirmar "Clonar os projetos e criar os ambientes virtuais (repositórios privados: precisa da chave SSH no GitHub)?"; then
    for p in "${PROJETOS[@]}"; do
        read -r repo destino <<<"$p"
        destino="$HOME/$destino"
        if [[ -e "$destino" ]]; then
            echo "  -> $destino já existe, mantido"
            continue
        fi
        mkdir -p "$(dirname "$destino")"
        if ! git clone -q "git@github.com:$repo.git" "$destino"; then
            echo "  -> falha ao clonar $repo (chave SSH configurada no GitHub?)"
            continue
        fi
        if [[ -f "$destino/requirements.txt" ]]; then
            python3 -m venv "$destino/.venv" && "$destino/.venv/bin/pip" install -q --disable-pip-version-check -r "$destino/requirements.txt"
        fi
        echo "  -> $repo em $destino"
    done

    # O que fica fora dos repositórios de propósito (segredos e dados pessoais)
    livros="$HOME/documents/estudos/faculdade/livros-organizacao"
    whatsapp="$HOME/documents/estudos/programacao/projetos/automacao-mensagem-whatsapp"
    mkdir -p "$HOME/documents/estudos/faculdade/livros" # pasta vigiada pelo livros-organizar.path
    if [[ -d "$livros" && ! -f "$livros/.env" ]]; then
        echo "  ! crie $livros/.env com ANTHROPIC_API_KEY, GEMINI_API_KEY e LIVROS_RCLONE (veja o README)"
    fi
    if [[ -d "$whatsapp" && ! -f "$whatsapp/mensagens.md" ]]; then
        cp "$whatsapp/mensagens.exemplo.md" "$whatsapp/mensagens.md"
        echo "  ! $whatsapp/mensagens.md criado a partir do exemplo; preencha com as suas mensagens"
        echo "  ! faça o login do WhatsApp uma vez: cd $whatsapp && .venv/bin/python login_whatsapp.py"
    fi
fi
echo

# 7. Serviços e relógio
echo "[7/7] Serviços: $(wc -l <services_system.txt) do sistema e $(wc -l <services_user.txt) do usuário; relógio do hardware em UTC"
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
