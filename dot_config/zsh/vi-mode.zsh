# ==============================================================================
# VIM MODE CONFIGURATION
# ==============================================================================

# Enable vi mode
bindkey -v

# Drastically reduce the delay (in deciseconds) when pressing <Esc> to switch modes
export KEYTIMEOUT=1

# Fix backspace behavior in vi mode (sometimes it stops working)
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# Allow Ctrl+R to still work for history search while in insert mode
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M vicmd '^r' history-incremental-search-backward

# Allow 'v' in normal mode to edit the current command line in your actual Vim/Neovim editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# ==============================================================================
# CURSOR SHAPE INDICATOR
# ==============================================================================
# Change cursor shape based on vi mode:
# - Normal mode: Block cursor (█)
# - Insert mode: Beam cursor (|)

function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
      echo -ne '\e[2 q' # Block
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
      echo -ne '\e[5 q' # Beam
  fi
}
zle -N zle-keymap-select

# Ensure the cursor resets to a beam when starting a new prompt
function _reset_cursor_to_beam() {
    echo -ne '\e[5 q'
}
precmd_functions+=(_reset_cursor_to_beam)
