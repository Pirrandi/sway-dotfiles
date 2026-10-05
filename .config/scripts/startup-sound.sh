#!/bin/bash
# Play the login sound once when sway starts.
#
# The audio file is NOT tracked in the dotfiles (it may be copyrighted): drop
# any startup.{ogg,mp3,flac,wav} into ~/.local/share/sounds/. No file, no sound.

SOUND=$(fd -1 -t f '^startup\.(ogg|mp3|flac|wav)$' "$HOME/.local/share/sounds" 2>/dev/null)
[ -n "$SOUND" ] && command -v pw-play >/dev/null || exit 0

# PipeWire is socket-activated but may still be settling right after login
sleep 1
exec pw-play "$SOUND"
