#!/bin/bash
# Monta a raiz do Google Drive (remote "gdrive") em ~/drive.
# Chamado pelo autostart do Hyprland; roda em segundo plano, então não atrasa o boot.
# Arquivos só são baixados quando abertos e ficam num cache local limitado.

PONTO="$HOME/drive"
LOG="$HOME/.cache/rclone/montar-drive.log"

mkdir -p "$PONTO" "$(dirname "$LOG")"

# Já montado? Não faz nada.
if mountpoint -q "$PONTO"; then
    exit 0
fi

# Espera a rede até 2 minutos
for _ in $(seq 1 60); do
    if rclone lsf gdrive: --max-depth 1 --dirs-only >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

rclone mount gdrive: "$PONTO" \
    --daemon \
    --vfs-cache-mode full \
    --vfs-cache-max-size 10G \
    --vfs-cache-min-free-space 5G \
    --vfs-cache-max-age 168h \
    --dir-cache-time 1000h \
    --poll-interval 1m \
    --umask 022 \
    --log-file "$LOG" \
    --log-level NOTICE

if ! mountpoint -q "$PONTO"; then
    notify-send -u critical "Google Drive" "Falha ao montar ~/drive. Veja $LOG"
fi
