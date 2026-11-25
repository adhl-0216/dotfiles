# ==============================================================================
# VI MODE
# ==============================================================================

bindkey -v
export KEYTIMEOUT=10

# bindkey -M viins '^n' vi-cmd-mode
# bindkey -M vicmd '^n' vi-insert
# bindkey -M viins '^[' undefined-key

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# ==============================================================================
# INSERT MODE
# ==============================================================================

bindkey -M viins '\eb' emacs-backward-word
bindkey -M viins '\ef' emacs-forward-word
bindkey -M viins '^p' history-search-backward
bindkey -M viins '^n' history-search-forward
bindkey -M viins '^a' beginning-of-line
bindkey -M viins '^e' end-of-line
bindkey -M viins '^b' backward-char
bindkey -M viins '^f' backward-char
bindkey -M viins '^d' delete-char
bindkey -M viins '^h' backward-delete-char
bindkey -M viins '^k' kill-line
bindkey -M viins '^u' backward-kill-line
bindkey -M viins '^w' backward-kill-word
bindkey -M viins '^y' yank

bindkey -M viins '^?' backward-delete-char


# ==============================================================================
# WIDGETS
# ==============================================================================

autoload -Uz copy-earlier-word
zle -N copy-earlier-word

bindkey -M viins '\e.' insert-last-word
bindkey -M viins '\e_' insert-last-word
bindkey -M viins '\e,' copy-earlier-word
bindkey -M viins '\em' copy-prev-shell-word
bindkey -M viins ' ' magic-space


# ==============================================================================
# AUTOSUGGESTIONS
# ==============================================================================

bindkey -M viins '^ ' autosuggest-accept
bindkey -M viins '^f' autosuggest-accept


# ==============================================================================
# CLIPBOARD
# ==============================================================================

function copy-command-buffer() {
    print -rn -- "$BUFFER" | wl-copy
}

zle -N copy-command-buffer

bindkey -M viins '\ec' copy-command-buffer
bindkey -M vicmd '\ec' copy-command-buffer


# ==============================================================================
# EXECUTE + COPY OUTPUT
# ==============================================================================

_execute_copy_output=0
_execute_copy_output_fd=

function execute-copy-output() {
    _execute_copy_output=1
    zle accept-line
}

zle -N execute-copy-output

bindkey -M viins '\e\C-j' execute-copy-output
bindkey -M vicmd '\e\C-j' execute-copy-output


function _execute_copy_output_preexec() {
    (( _execute_copy_output )) || return

    exec {_execute_copy_output_fd}>&1
    exec > >(tee >(wl-copy)) 2>&1
}

function _execute_copy_output_precmd() {
    (( _execute_copy_output )) || return

    exec 1>&${_execute_copy_output_fd}
    exec 2>&1
    exec {_execute_copy_output_fd}>&-

    _execute_copy_output=0
}

preexec_functions+=(_execute_copy_output_preexec)
precmd_functions+=(_execute_copy_output_precmd)


# ==============================================================================
# CURSOR
# ==============================================================================

function zle-keymap-select() {
    if [[ ${KEYMAP} == vicmd ]]; then
        print -n '\e[2 q'
    else
        print -n '\e[5 q'
    fi

    zle reset-prompt
}

zle -N zle-keymap-select

function _reset_cursor_to_beam() {
    print -n '\e[5 q'
}

precmd_functions+=(_reset_cursor_to_beam)
