#!/usr/bin/env bash
# Aba "Scripts" do launcher (modo script do rofi; registrada no style-5.rasi).
# Sem argumento: lista as ações. Com argumento: executa a ação escolhida e fecha o rofi.
# Para adicionar uma ação: uma linha em ACOES e um caso no "case" abaixo.

ACOES=(
    "Montar Google Drive (~/drive)"
    "Desmontar Google Drive"
    "Estado do Google Drive"
    "Reconectar Google Drive (token expirado)"
    "Organizar livros da faculdade agora"
    "Abrir guia da organização de arquivos"
)

avisar() { notify-send -a "Scripts" "$1" "$2"; }
# roda desligado do rofi (senão ele fica aberto esperando a saída)
solto() { setsid -f "$@" >/dev/null 2>&1; }

if [[ -z "$1" ]]; then
    printf '%s\n' "${ACOES[@]}"
    exit 0
fi

case "$1" in
    "Montar Google Drive"*)
        if mountpoint -q "$HOME/drive"; then
            avisar "Google Drive" "Já está montado em ~/drive."
        else
            avisar "Google Drive" "Montando ~/drive…"
            solto "$HOME/.config/hypr/scripts/montar-drive.sh"
        fi ;;
    "Desmontar Google Drive")
        if fusermount3 -u "$HOME/drive" 2>/dev/null; then
            avisar "Google Drive" "Desmontado."
        else
            avisar "Google Drive" "Não estava montado (ou há arquivos abertos nele)."
        fi ;;
    "Estado do Google Drive")
        if mountpoint -q "$HOME/drive"; then estado="Montado em ~/drive."; else estado="Não montado."; fi
        if timeout 20 rclone lsf gdrive: --max-depth 1 --dirs-only >/dev/null 2>&1; then
            token="Acesso ao Drive OK."
        else
            token="Sem acesso: token expirado ou sem internet."
        fi
        avisar "Google Drive" "$estado\n$token" ;;
    "Reconectar Google Drive"*)
        solto kitty --title "Reconectar Google Drive" bash -c \
            'echo "Em \"Token already configured - replace it?\" responda y; nas outras, Enter (padrão)."; echo
             rclone config reconnect gdrive: && ~/.config/hypr/scripts/montar-drive.sh; echo; read -rp "Enter para fechar"' ;;
    "Organizar livros"*)
        # o serviço identifica os livros novos de faculdade/livros (IA), classifica pelo PPC, cria os links
        # nas disciplinas e envia ao gdrive:faculdade; ao terminar ele mesmo avisa o resumo
        avisar "Livros" "Organizando os livros novos…"
        solto bash -c 'systemctl --user start livros-organizar.service ||
            notify-send -u critical -a Livros "Livros" "A organização falhou. Veja: journalctl --user -u livros-organizar -n 50"' ;;
    "Abrir guia da organização"*)
        solto xdg-open "$HOME/documents/sistema/organizacao-de-arquivos.md" ;;
esac
