---
name: Zenity sudo prompt
description: Obtain sudo authorization through a graphical zenity dialog when the shell has no TTY or the user asks for a GUI password prompt. Use for privileged commands from an agent, automation, or a non-interactive session. Every dialog must state the concrete action being authorized.
---

# Zenity sudo prompt

Run privileged commands with a graphical password prompt instead of a terminal
prompt. The dialog summarizes exactly what is being authorized.

## Why this works

`sudo` uses `$SUDO_ASKPASS` when `-A` is given or when no terminal is available
(see `man sudo`, ENVIRONMENT). The askpass helper prints the password to stdout
and sudo consumes it. The helper never stores the password.

`zenity --password` in zenity 4.2.2 accepts only a title, so this skill uses
`zenity --entry --hide-text`, which also accepts `--text` (verified with
`zenity --help-entry`). The input stays masked.

## Preconditions

Check these before prompting; do not guess:

```bash
[[ -n ${WAYLAND_DISPLAY:-}${DISPLAY:-} ]] && echo "gui ok"
command -v zenity && command -v sudo
```

Also useful: `XDG_RUNTIME_DIR`, `DBUS_SESSION_BUS_ADDRESS`. If there is no
graphical session, do not attempt the dialog.

## Standard method

Use `scripts/sudo-gui.sh` (relative to this skill directory):

```bash
./scripts/sudo-gui.sh DESCRIPTION COMMAND [ARGS...]
./scripts/sudo-gui.sh --title TITLE DESCRIPTION COMMAND [ARGS...]
```

Examples (run from this skill's base directory):

```bash
./scripts/sudo-gui.sh "Restart NetworkManager to apply the new DNS settings; network drops for ~2s" \
  systemctl restart NetworkManager

./scripts/sudo-gui.sh "Uninstall goose-desktop-bin and delete its orphaned files in /opt/goose-desktop" \
  bash -c 'pacman -Rdd --noconfirm --noscriptlet goose-desktop-bin && rm -rf /opt/goose-desktop'

./scripts/sudo-gui.sh "Install telegram-desktop-bin 7.4.4-1 from the AUR build cache" \
  pacman -U --noconfirm /var/cache/paru/telegram-desktop-bin-7.4.4-1-x86_64.pkg.tar.zst
```

The helper writes a temporary askpass script (mode 700) that embeds the
description and the command line, runs `sudo -A`, and removes it on exit.
`SUDO_GUI_TIMEOUT` overrides the dialog timeout in seconds (default 180).

## Writing the description

The description is the point of the skill. It must let the user decide without
seeing the command.

Include:

1. the verb and exact object (package, unit, file, path),
2. the scope or impact (files removed, service interruption, packages changed),
3. reversibility when it is not obvious.

| Bad | Good |
| --- | --- |
| `sudo` | `Uninstall goose-desktop-bin and delete /opt/goose-desktop` |
| `Run command` | `Restart sddm; the current graphical session will be logged out` |
| `Update system` | `Install 3 package updates including the 7.3.4 kernel; reboot needed` |
| `Fix files` | `Delete the zeroed files left by the failed goose install in /usr/bin and /opt` |

Rules:

- Never write a generic placeholder. State what changes.
- Do not put secrets in the description or command; both are visible on screen.
- For multi-step work, batch it into one `sudo-gui ... bash -c '...'` call so the
  user authorizes once, and describe the whole batch.
- If an action is high risk (boot, network, auth, data loss), say so in the
  description and include the backout in the same sentence when short.

## After the command

- Check the exit status; a canceled dialog makes sudo fail with
  "no password was provided".
- Verify the result with read-only commands (`pacman -Q`, `systemctl status`,
  `file`, log tail) and report the observed facts.
- Never claim success from the dialog alone.

## Fallback

If no GUI is available or the user declines the dialog, print the exact command
for the user to run in a terminal. Never ask the user to paste a password into
chat, and never use `sudo -S` with a password from the conversation.

If the dialog does not appear, check `WAYLAND_DISPLAY`/`DISPLAY`,
`XDG_RUNTIME_DIR`, and that the process runs as the desktop user. On a tty,
sudo may skip the helper because credentials are cached; that is expected.

## Manual helper (when not using the script)

```bash
tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT
cat >"$tmp/askpass" <<'EOF'
#!/bin/sh
exec zenity --entry --hide-text --no-markup \
  --title="Administrator access" \
  --text="DESCRIPTION GOES HERE (action, target, impact)" \
  --ok-label="Authenticate" --timeout=120
EOF
chmod 700 "$tmp/askpass"
SUDO_ASKPASS="$tmp/askpass" sudo -A COMMAND
```
