# ==============================================================================
# ZINIT
# ==============================================================================

ZINIT_HOME="${ZINIT_HOME:-$HOME/.local/share/zinit/zinit.git}"

if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    print -P "%F{33}▓▒░ %F{34}Installing Zinit...%f"
    mkdir -p "${ZINIT_HOME:h}"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"


# ==============================================================================
# COMPLETION PLUGINS
# ==============================================================================

zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab


# ==============================================================================
# WIDGET PLUGINS
# ==============================================================================

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting


# ==============================================================================
# OH-MY-ZSH LIBRARIES
# ==============================================================================

zinit snippet OMZ::lib/completion.zsh
zinit snippet OMZ::lib/history.zsh
zinit snippet OMZ::lib/key-bindings.zsh

zinit snippet OMZL::git.zsh
zinit snippet OMZL::directories.zsh
zinit snippet OMZL::theme-and-appearance.zsh
zinit snippet OMZL::async_prompt.zsh


# ==============================================================================
# OH-MY-ZSH PLUGINS
# ==============================================================================

zinit snippet OMZP::git
zinit snippet OMZP::eza
zinit snippet OMZP::sudo
