#!/bin/bash
# Waybar custom/ctx-workspaces: workspaces of the active context (work/personal),
# rendered as "work: ●1 ○2 ○3".
#
# One-shot: renders once and exits, driven by waybar's interval + RTMIN+1.
# The cost here was never the polling itself but what each tick paid for: the
# old version started bash + cat + a full python3 interpreter (~28ms/tick),
# while the swaymsg query it wraps costs 1.6ms. Dropping python for jq and
# `cat` for bash's $(<file) keeps identical behaviour for a fraction of the price.

CTX_FILE=/tmp/sway-ctx

ctx=""
[ -r "$CTX_FILE" ] && ctx=$(<"$CTX_FILE")
ctx=${ctx//[[:space:]]/}
[ -n "$ctx" ] || ctx=work

swaymsg -t get_workspaces -r 2>/dev/null | jq -r --arg ctx "$ctx" '
    [ .[]
      | select(.name | startswith($ctx + ":"))
      | { n: (.name | split(":") | .[1] | tonumber), f: .focused }
    ]
    | sort_by(.n)
    | map((if .f then "●" else "○" end) + (.n | tostring))
    | (if length == 0 then "○1" else join(" ") end)
    | $ctx + ": " + .
'
