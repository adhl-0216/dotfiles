# ==============================================================================
# COMPLETION
# ==============================================================================

fpath=("$ZDOTDIR/completions" $fpath)

autoload -Uz compinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# ==============================================================================
# HISTORY
# ==============================================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=10000

setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt AUTO_CD

# ==============================================================================
# TMUX
# ==============================================================================

# if [ -z "$TMUX" ]; then
#   tmux new -s $(petname)
# fi
