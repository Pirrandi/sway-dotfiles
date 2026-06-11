#!/bin/bash
# Uso: ctx.sh work | ctx.sh personal
CTX=$1
CTX_FILE=/tmp/sway-ctx

case $CTX in
    work)
        echo "work" > $CTX_FILE
        swaymsg "workspace work:1"
        notify-send "Contexto" "💼 Trabajo" -t 2000
        ;;
    personal)
        echo "personal" > $CTX_FILE
        swaymsg "workspace personal:1"
        notify-send "Contexto" "🏠 Personal" -t 2000
        ;;
esac
