#!/bin/bash
# Cicla el layout del teclado (us <-> latam) y notifica cuál quedó activo.
# Los layouts se declaran en ~/.config/sway/config.d/input.conf

swaymsg input type:keyboard xkb_switch_layout next >/dev/null

# Todos los teclados comparten la misma config, así que alcanza con el primero
# que reporte un layout con nombre.
LAYOUT=$(swaymsg -t get_inputs -r | jq -r '
    map(select(.type == "keyboard" and .xkb_active_layout_name != null))
    | .[0].xkb_active_layout_name // empty
')

[ -z "$LAYOUT" ] && exit 0

# El hint synchronous hace que mako reemplace la notificación anterior en vez
# de apilarlas cuando cambiás de layout varias veces seguidas.
notify-send "Layout de teclado" "⌨  ${LAYOUT}" -t 1500 \
    -h string:x-canonical-private-synchronous:keyboard-layout
