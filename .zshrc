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

# Plugins directos (sin OMZ)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

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
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#3a3a3a'

# fzf — Ctrl+R history search, Ctrl+T file picker, Alt+C cd
command -v fzf >/dev/null && source <(fzf --zsh)

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
