#!/usr/bin/env bash
# sudo-gui - run a command under sudo, asking for the password in a zenity
# dialog that describes exactly what is being authorized.
#
# Usage:
#   sudo-gui [--title TITLE] DESCRIPTION COMMAND [ARGS...]
#
# The DESCRIPTION is shown in the dialog above the command line. Keep it
# specific: verb, target, impact.
set -euo pipefail

prog=${0##*/}

usage() {
  cat >&2 <<'EOF'
Usage: sudo-gui [--title TITLE] DESCRIPTION COMMAND [ARGS...]

  DESCRIPTION  Specific, user-facing summary of the action being authorized.
  COMMAND...   Command passed to sudo (sudo-gui adds -A).

Examples:
  sudo-gui "Restart NetworkManager; network drops for ~2s" systemctl restart NetworkManager
  sudo-gui "Uninstall goose-desktop-bin and delete /opt/goose-desktop" \
    bash -c 'pacman -Rdd --noconfirm goose-desktop-bin && rm -rf /opt/goose-desktop'

Environment:
  SUDO_GUI_TIMEOUT  Dialog timeout in seconds (default 120).
EOF
}

die() { printf '%s: %s\n' "$prog" "$*" >&2; exit 1; }

title="Administrator access"
case ${1:-} in
  -h|--help) usage; exit 0 ;;
  --title)
    [[ $# -ge 3 ]] || { usage; exit 2; }
    title=$2
    shift 2
    ;;
esac

[[ $# -ge 2 ]] || { usage; exit 2; }
description=$1
shift

# --- validate the description: it must actually describe the action -------
[[ -n ${description//[[:space:]]/} ]] || die "DESCRIPTION must not be empty"
(( ${#description} >= 12 )) || die "DESCRIPTION is too short; name the action and its target"

case ${description,,} in
  sudo|sudo\ required|admin|administrator|root|root\ access|privileged\ action|\
  run\ command|run\ commands|execute\ command|perform\ operation)
    die "DESCRIPTION is too generic; state what changes and where"
    ;;
esac

# --- prerequisites ---------------------------------------------------------
[[ -n ${WAYLAND_DISPLAY:-}${DISPLAY:-} ]] \
  || die "no graphical session (WAYLAND_DISPLAY/DISPLAY are unset)"
command -v zenity >/dev/null 2>&1 || die "zenity is not installed"
command -v sudo >/dev/null 2>&1 || die "sudo is not installed"
command -v base64 >/dev/null 2>&1 || die "base64 is not installed"

# --- build the dialog text -------------------------------------------------
cmd=$(printf '%q ' "$@")
cmd=${cmd% }
(( ${#cmd} > 160 )) && cmd="${cmd:0:157}..."
text="$description

Command: sudo $cmd"

# base64 keeps arbitrary characters out of the generated shell script
title_b64=$(printf '%s' "$title" | base64 -w0)
text_b64=$(printf '%s' "$text" | base64 -w0)

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/sudo-gui.XXXXXX") || die "mktemp failed"
trap 'rm -rf -- "$tmpdir"' EXIT
askpass=$tmpdir/askpass

cat >"$askpass" <<EOF
#!/bin/sh
title=\$(printf '%s' '$title_b64' | base64 -d)
text=\$(printf '%s' '$text_b64' | base64 -d)
exec zenity --entry --hide-text --no-markup \\
  --title="\$title" \\
  --text="\$text" \\
  --ok-label="Authenticate" --cancel-label="Cancel" \\
  --width=460 \\
  --timeout="\${SUDO_GUI_TIMEOUT:-180}"
EOF
chmod 700 "$askpass"

SUDO_ASKPASS=$askpass sudo -A "$@"
