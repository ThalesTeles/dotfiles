#!/bin/bash
# Dá um pequeno tempo para o compositor carregar
sleep 1

# Garante que não há instâncias zumbis rodando
killall -q xdg-desktop-portal-hyprland xdg-desktop-portal

# Inicia o portal do Hyprland e aguarda ele se registrar
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2

# Inicia o portal principal
/usr/lib/xdg-desktop-portal &
