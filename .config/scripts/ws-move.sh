#!/bin/bash
CTX_FILE=/tmp/sway-ctx
CTX=$(cat $CTX_FILE 2>/dev/null || echo "work")
NUM=$(printf "%02d" $1)
swaymsg "move container to workspace ${CTX}:${NUM}"
