#!/bin/sh
# Punto de entrada de Alacritty hacia tmux.
# - "main" es la sesión persistente (también accesible desde el teléfono).
# - Si "main" ya tiene un cliente, se crea una sesión extra desechable que
#   se destruye al desconectarse (destroy-unattached solo en esa sesión).

if ! tmux has-session -t '=main' 2>/dev/null; then
  exec tmux new-session -s main
fi

attached=$(tmux display-message -p -t '=main:' '#{session_attached}' 2>/dev/null)
if [ "${attached:-0}" -eq 0 ]; then
  exec tmux attach-session -t '=main'
fi

# Create and attach in one step: a detached session would be destroyed
# before attaching if destroy-unattached were already on globally.
exec tmux new-session -c "$HOME" \; set-option destroy-unattached on
