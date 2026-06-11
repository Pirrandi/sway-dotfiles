#!/bin/bash
CTX_FILE=/tmp/sway-ctx
CONTEXTS_FILE=$HOME/.config/scripts/contexts.txt
BINDS_FILE=$HOME/.config/sway/config.d/ctx-binds.conf

if [ ! -f "$CONTEXTS_FILE" ]; then
    echo -e "personal\nwork" > $CONTEXTS_FILE
fi

generate_binds() {
    echo "# Contextos - generado automáticamente" > $BINDS_FILE
    local i=1
    while IFS= read -r ctx; do
        echo "bindsym \$mod+F${i} exec bash -c 'echo ${ctx} > $CTX_FILE && swaymsg workspace ${ctx}:01 && pkill -RTMIN+1 waybar && notify-send Contexto ${ctx} -t 1500'" >> $BINDS_FILE
        i=$((i+1))
    done < $CONTEXTS_FILE
    swaymsg reload
}

CONTEXTS=$(cat $CONTEXTS_FILE)

WS_OPTIONS=""
while IFS= read -r ctx; do
    for i in $(seq -w 1 10); do
        WS_OPTIONS+="󰖲  Ir a ${ctx}:${i}\n"
    done
done <<< "$CONTEXTS"

MOVE_OPTIONS=""
while IFS= read -r ctx; do
    for i in $(seq -w 1 10); do
        MOVE_OPTIONS+="󰆾  Mover ventana a ${ctx}:${i}\n"
    done
done <<< "$CONTEXTS"

OPTION=$(echo -e "${WS_OPTIONS}${MOVE_OPTIONS}󰐕  Nuevo contexto..." | wofi --show dmenu --prompt "Contextos:" --width 350 --height 500)

case "$OPTION" in
    *"Ir a "*)
        WS=$(echo "$OPTION" | grep -oP '[a-zA-Z]+:\d+')
        CTX_NAME=$(echo "$WS" | cut -d: -f1)
        echo "$CTX_NAME" > $CTX_FILE
        swaymsg "workspace $WS"
        pkill -RTMIN+1 waybar
        notify-send "Contexto" "📁 $WS" -t 1500
        ;;
    *"Mover ventana a "*)
        WS=$(echo "$OPTION" | grep -oP '[a-zA-Z]+:\d+')
        swaymsg "move container to workspace $WS"
        notify-send "Movido" "📁 $WS" -t 1500
        ;;
    *"Nuevo contexto"*)
        NEW_CTX=$(echo "" | wofi --show dmenu --prompt "Nombre del contexto:")
        if [ -n "$NEW_CTX" ]; then
            echo "$NEW_CTX" >> $CONTEXTS_FILE
            echo "$NEW_CTX" > $CTX_FILE
            generate_binds
            swaymsg "workspace ${NEW_CTX}:01"
            pkill -RTMIN+1 waybar
            notify-send "Contexto creado" "📁 ${NEW_CTX} → F$(grep -n "$NEW_CTX" $CONTEXTS_FILE | cut -d: -f1)" -t 2000
        fi
        ;;
esac

[ ! -f "$BINDS_FILE" ] && generate_binds
