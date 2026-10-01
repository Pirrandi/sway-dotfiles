#!/bin/sh
# Pinta la barra de estado en rojo cuando la sesión viene de una conexión SSH.
# Se ejecuta desde los hooks client-attached y session-created de tmux.
# Nunca debe fallar: cualquier error se ignora y se sale con 0.

session="$1"
[ -n "$session" ] || exit 0

case "$(tmux show-environment -t "=$session" SSH_CONNECTION 2>/dev/null)" in
  SSH_CONNECTION=*)
    tmux set-option -t "=${session}:" status-style 'bg=#2a0f1c,fg=#ee5396' 2>/dev/null
    tmux set-option -t "=${session}:" status-right '#[fg=#ee5396,bold] 󰣀 SSH #[fg=#ee5396] 󰒋 #h #[fg=#ee5396,bold] 󰥔 %H:%M ' 2>/dev/null
    ;;
  *)
    tmux set-option -t "=${session}:" -u status-style 2>/dev/null
    tmux set-option -t "=${session}:" -u status-right 2>/dev/null
    ;;
esac

exit 0
