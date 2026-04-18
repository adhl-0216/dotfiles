# ==============================================================================
# ALIASES (CACHYOS, SYSTEM, AND SENSIBLE DEFAULTS)
# ==============================================================================

# Eza replacing standard ls commands
if command -v eza &> /dev/null; then
    alias ls='eza -al --color=always --group-directories-first --icons=always'
    alias la='eza -a --color=always --group-directories-first --icons=always'
    alias ll='eza -l --color=always --group-directories-first --icons=always'
    alias lt='eza -aT --color=always --group-directories-first --icons=always'
    alias l.="eza -a | grep -e '^\.'"
fi

# Common CachyOS Administration & Quick Actions
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'


# Sensible Replacements for standard tools
if command -v bat &> /dev/null; then
    alias cat='bat'
fi
if command -v duf &> /dev/null; then
    alias df='duf'
fi

# Yazi terminal file manager (wrapper function is defined in .zshrc)
if command -v yazi &> /dev/null; then
    alias y='yy'
fi

# CachyOS System Updates (Checks for paru, then yay, then pacman)
if command -v paru &> /dev/null; then
    alias update='paru -Syu'
elif command -v yay &> /dev/null; then
    alias update='yay -Syu'
elif command -v pacman &> /dev/null; then
    alias update='sudo pacman -Syu'
fi

alias v=nvim
alias vim=nvim
alias ff=fastfetch
