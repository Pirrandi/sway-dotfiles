#!/bin/bash
# Usage: screenshot.sh full|area|clip
#   full  whole screen -> file + clipboard
#   area  selection    -> file + clipboard
#   clip  selection    -> clipboard only
DIR="$HOME/Pictures/Screenshots"
FILE="$DIR/$(date +%F_%H-%M-%S).png"

case "$1" in
    full) GEOM="" ;;
    area|clip) GEOM=$(slurp) || exit 0 ;;
    *) echo "usage: $0 full|area|clip" >&2; exit 1 ;;
esac

if [ "$1" = clip ]; then
    grim ${GEOM:+-g "$GEOM"} - | wl-copy --type image/png
    notify-send "Screenshot" "Selección copiada al clipboard" -t 1500
    exit 0
fi

mkdir -p "$DIR"
grim ${GEOM:+-g "$GEOM"} "$FILE" || exit 1
wl-copy --type image/png < "$FILE"
notify-send "Screenshot" "Guardado en ${FILE/#$HOME/\~} y copiado" -i "$FILE" -t 2500
