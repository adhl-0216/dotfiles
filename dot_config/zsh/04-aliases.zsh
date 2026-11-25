# ==============================================================================
# ALIASES (CACHYOS, SYSTEM, AND SENSIBLE DEFAULTS)
# ==============================================================================

# Eza replacing standard ls commands
if command -v eza &> /dev/null; then
    alias ls='eza -l --color=always --group-directories-first --icons=always'
    alias la='eza -al --color=always --group-directories-first --icons=always'
    alias ll='eza -l --color=always --group-directories-first --icons=always'
    alias lt='eza -aT --color=always --group-directories-first --icons=always'
    alias l.="eza -a | grep -e '^\.'"
fi

# Common CachyOS Administration & Quick Actions
# fixpacman -> full repair script in ~/.local/bin (stale DB lock: fixpacman --fix-lock)
alias fixpacman='$HOME/.local/bin/fixpacman'
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'


# Sensible Replacements for standard tools
if command -v duf &> /dev/null; then
    alias df='duf'
fi

# Yazi terminal file manager (wrapper function is defined in .zshrc)
if command -v yazi &> /dev/null; then
    alias y='yy'
fi


alias cd=z

function mkcd(){
  mkdir $1 && cd $1
}

alias v=nvim
alias vim=nvim
alias ff=fastfetch

function cfgedit(){
  local target="$1"
  local dir="${target:h}"
  nvim $target -c "cd $dir"
}
alias zshconf="cfgedit $ZDOTDIR/.zshrc"
alias niriconf="cfgedit $XDG_CONFIG_HOME/niri/config.kdl"
alias termconf="cfgedit $XDG_CONFIG_HOME/ghostty/config"
alias aliasconf="cfgedit $XDG_CONFIG_HOME/zsh/aliases.zsh"
alias tmuxconf="cfgedit $XDG_CONFIG_HOME/tmux/tmux.conf"

alias open=xdg-open
alias oc=opencode

# Re-add modified managed dotfiles to chezmoi, show leftovers, then push
cmup() {
    chezmoi re-add "$@"
    chezmoi status
    chezmoi push
}
