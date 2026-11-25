# ==============================================================================
# FZF
# ==============================================================================

if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

# ==============================================================================
# FZF-TAB
# ==============================================================================

zstyle ':fzf-tab:*' fzf-bindings \
    'ctrl-j:down' \
    'ctrl-k:up' \
    'ctrl-space:toggle'

zstyle ':fzf-tab:*' switch-group '[' ']'

zstyle ':fzf-tab:complete:cd:*' \
    fzf-preview 'eza -1 --icons --color=always $realpath'

zstyle ':fzf-tab:complete:__zoxide_z:*' \
    fzf-preview 'eza -1 --icons --color=always $realpath'

# ==============================================================================
# ATUIN
# ==============================================================================

if command -v atuin &>/dev/null; then
    eval "$(atuin init zsh)"

    # Atuin is the authoritative source of truth for suggestions.
    # `atuin init` prepends its atuin strategy to the existing one, but the
    # zsh-history ("history") strategy remains as a fallback, so commands
    # that were filtered, never stored, or deleted in atuin would still
    # resurface from zsh's own HISTFILE. Override to drop every fallback:
    # suggestions may only come from what atuin itself would show.
    ZSH_AUTOSUGGEST_STRATEGY=(atuin)
fi

# Ctrl+R: atuin-search
if (( $+widgets[atuin-search] )); then
    bindkey -M viins '^r' atuin-search
    bindkey -M vicmd '^r' atuin-search
fi

# ==============================================================================
# ZOXIDE
# ==============================================================================

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi


# ==============================================================================
# MISE
# ==============================================================================

if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi


# ==============================================================================
# STARSHIP
# ==============================================================================

if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi


# ==============================================================================
# MAN
# ==============================================================================

export MANROFFOPT="-c"

if command -v bat &>/dev/null; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi


# ==============================================================================
# FASTFETCH
# ==============================================================================

if [[ -o interactive ]] && command -v fastfetch &>/dev/null; then
    fastfetch
fi

# ==============================================================================
# TIMG
# ==============================================================================

if command -v timg &>/dev/null; then
    function timg() {
        command timg -pk "$@"
    }
fi


# ==============================================================================
# YAZI
# ==============================================================================

if command -v yazi &>/dev/null; then
    function yy() {
        local tmp cwd

        tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return

        yazi "$@" --cwd-file="$tmp"

        if [[ -r "$tmp" ]]; then
            cwd="$(<"$tmp")"

            if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
                builtin cd -- "$cwd"
            fi
        fi

        rm -f -- "$tmp"
    }
fi
