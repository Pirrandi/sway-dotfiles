# Acceso remoto (ssh/mosh desde el teléfono): entra directo a tmux, agrupado
# con "main" (mismas ventanas, navegación independiente). Al desconectarse
# con prefix+d se cierra también la conexión. Debe ir antes del instant prompt.
if [[ -o interactive && -z $TMUX ]] && (( $+commands[tmux] )) &&
   [[ -n $SSH_CONNECTION || "$(ps -o comm= -p $PPID)" == mosh-server ]]; then
  tmux has-session -t '=main' 2>/dev/null || tmux new-session -d -s main
  tmux new-session -A -t main -s phone && exit
fi

# Instant prompt p10k
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Historia
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory sharehistory incappendhistory
setopt hist_ignore_all_dups hist_ignore_space hist_reduce_blanks

# Completion — arrow-key menu, case-insensitive matching
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Completion colors — LS_COLORS for files, carbonfox for headers and selection
eval "$(dircolors -b)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} 'ma=48;2;42;42;42;1'
zstyle ':completion:*:descriptions' format '%F{#78a9ff}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{#ee5396}-- no matches --%f'
zstyle ':completion:*' group-name ''

# Plugins directos (sin OMZ)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting — must load before history-substring-search
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ee5396'
ZSH_HIGHLIGHT_STYLES[command]='fg=#25be6a'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#25be6a'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#25be6a'
ZSH_HIGHLIGHT_STYLES[function]='fg=#25be6a'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#25be6a,italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#be95ff'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#be95ff'
ZSH_HIGHLIGHT_STYLES[path]='fg=#78a9ff,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#33b1ff'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#3ddbd9'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#3ddbd9'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#ff7eb6'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#ff7eb6'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#33b1ff'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#be95ff'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6e6f70'

source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=#2a2a2a,fg=#f2f4f8,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=#ee5396,bold'

# Keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Treat '.', '-' and '/' as word separators (stop at them on word motions/deletions)
WORDCHARS=${WORDCHARS//[.\/-]/}

# Word navigation (Ctrl+Left/Right)
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[Od'    backward-word   # urxvt/rxvt
bindkey '^[Oc'    forward-word

# Word deletion
bindkey '^[[3;3~' kill-word           # Alt+Delete
bindkey '^[[3;5~' kill-word           # Ctrl+Delete
bindkey '^[^?'    backward-kill-word  # Alt+Backspace
bindkey '^H'      backward-kill-word  # Ctrl+Backspace

# Line navigation and plain Delete
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char

# Autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#525253'

# fzf — carbonfox colors, minimal layout
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=rounded --info=inline-right \
  --pointer='▌' --marker='▍' --prompt=' ' \
  --color=bg:-1,bg+:#2a2a2a,fg:#b6b8bb,fg+:#f2f4f8,hl:#78a9ff,hl+:#8cb6ff \
  --color=border:#3c3c3c,prompt:#be95ff,pointer:#ff7eb6,marker:#25be6a,spinner:#3ddbd9,info:#7b7c7e,header:#7b7c7e"

# fzf — Ctrl+R history search, Ctrl+T file picker, Alt+C cd
command -v fzf >/dev/null && source <(fzf --zsh)

# zoxide — z <partial> jumps to a frecent dir, zi opens the fzf picker
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# PATH — typeset -U drops duplicates, so nested shells (tmux panes) don't grow it
typeset -U path
export BUN_INSTALL="$HOME/.bun"
path=("$HOME/.npm-global/bin" "$BUN_INSTALL/bin" "$HOME/.local/bin" $path)
export EDITOR=nvim

# Flatpak — tied array keeps XDG_DATA_DIRS unique; falls back to the spec
# default so /usr/share is never lost when the variable starts empty
typeset -TUx XDG_DATA_DIRS xdg_data_dirs
(( ${#xdg_data_dirs} )) || xdg_data_dirs=(/usr/local/share /usr/share)
xdg_data_dirs=(/var/lib/flatpak/exports/share "$HOME/.local/share/flatpak/exports/share" $xdg_data_dirs)

# p10k
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# bun
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# eza aliases
alias ls='eza'
alias ll='eza -lah --icons'
alias la='eza -a --icons'
alias lt='eza --tree --level=2 --icons'
alias l='eza -l --icons'

# tmux — "main" es la sesión persistente
alias tm='tmux new-session -A -s main'
# Desde el teléfono: sesión agrupada con "main" (comparte ventanas, pero
# cada cliente elige su propia ventana activa)
alias tphone='tmux new-session -A -t main -s phone'

# ssh/mosh dentro de tmux: tiñe el panel de rojo mientras dura la conexión
_tmux_remote() {
  if [[ -z $TMUX ]]; then
    command "$@"
    return
  fi
  local rc
  {
    tmux select-pane -P 'bg=#1f0f16' -T "$*"
    command "$@"
    rc=$?
  } always {
    tmux select-pane -P 'bg=default'
  }
  return $rc
}
ssh()  { _tmux_remote ssh "$@" }
mosh() { _tmux_remote mosh "$@" }
