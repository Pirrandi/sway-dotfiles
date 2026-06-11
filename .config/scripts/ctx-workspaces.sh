#!/bin/bash
CTX_FILE=/tmp/sway-ctx
CTX=$(cat $CTX_FILE 2>/dev/null || echo "work")

swaymsg -t get_workspaces | python3 -c "
import json, sys
ws = json.load(sys.stdin)
try:
    ctx = open('$CTX_FILE').read().strip()
except:
    ctx = 'work'
result = []
for w in sorted(ws, key=lambda x: x['name']):
    if w['name'].startswith(ctx + ':'):
        num = str(int(w['name'].split(':')[1]))
        focused = '●' if w['focused'] else '○'
        result.append(f'{focused}{num}')
print(ctx + ': ' + (' '.join(result) if result else '○1'))
"
