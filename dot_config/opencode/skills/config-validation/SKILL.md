---
name: Config validation
description: Validate a configuration file offline before reloading or restarting whatever reads it. Use when editing any /etc config, a systemd unit or drop-in, sudoers, sshd_config, shell rc files, sysctl, fstab, or a Wayland compositor config, and when choosing between reload and restart.
---

# Config validation

The agent prompt requires validating configuration before a restart "when a
validator exists" (Changes). This skill supplies the validators and the
procedure. Validation proves a file parses; verification proves the service
behaves. Do both, in that order, and never use a restart as your first syntax
check on something that can be checked offline.

## Method

1. Establish which file is actually read. Deployed config is often merged, and
   a drop-in or package default can shadow the file you edited:

   ```bash
   systemctl cat <unit>                      # merged unit + drop-ins
   systemd-analyze cat-config <name|path>    # merged config with drop-ins
   pacman -Qo /etc/path/to/file              # owning package
   ```

2. Back up the file and record its permissions (see `change-backout`).
3. Run the validator as the account it requires (many need root).
4. Only then `reload`, `restart`, or `reload-or-restart`.
5. Verify live behaviour, not the exit code.

## Validators

| Target | Command | Root | Notes |
|---|---|---|---|
| sshd | `sshd -t` | yes | Verified: as a normal user this fails with `no hostkeys available`, which is a permission artefact, not a config error |
| sudoers | `visudo -c` (`-q` quiet) | yes | Verified: as a normal user it reports `unable to open /etc/sudoers: Permission denied` |
| systemd unit | `systemd-analyze verify /path/unit.service` | no | Verified unprivileged; checks syntax and references, not runtime behaviour |
| systemd merged unit | `systemctl cat <unit>` | no | Shows vendor file plus every drop-in in precedence order |
| zsh | `zsh -n file` | no | Verified with zsh 5.9.2 |
| bash | `bash -n file` | no | |
| niri | `niri validate` | no | Verified; loads `~/.config/niri/config.kdl` and prints `config is valid` |
| fstab | `findmnt --verify` | no | Verified `Success, no errors or warnings detected`. Do **not** use `mount -a` as a test on a live system |
| pacman.conf | `pacman-conf <directive>` | no | Parses and prints effective values; no dry-run install exists |
| logrotate | `logrotate -d /etc/logrotate.conf` | no | Debug mode makes no changes |
| sysctl | none | — | `sysctl --system` applies immediately; pre-check each key with `sysctl -n` |
| nginx | `nginx -t` | no | Not installed on this machine; if installed, use it |
| other daemons | `<daemon> -t`, `--test-config`, or a `check` subcommand | varies | Confirm in `man <daemon>` before assuming a flag exists |

Root-requiring validators need a privilege path. If no TTY is available, use
the `zenity-sudo` skill rather than inventing a password mechanism.

## Reload versus restart

- `systemctl reload` only works if the unit advertises `CanReload=yes`:

  ```bash
  systemctl show <unit> -p CanReload
  ```

  Otherwise use `systemctl reload-or-restart` or `restart`.
- `systemctl edit` reloads the manager automatically. Hand-written unit files
  do not: run `systemctl daemon-reload` first.
- A reload can exit 0 and do nothing (no reload path, stale config path). Verify
  with the journal plus a functional check.

## Verification matrix

| Change | Functional check |
|---|---|
| sshd | new session attempt, existing sessions untouched; `ss -tlnp` still listening |
| sudoers | `sudo -n true` for an authorised user; `visudo -c` again |
| systemd unit | `systemctl status --no-pager`, `journalctl -u <unit> -b -n 50 --no-pager` |
| timer | `systemctl list-timers --all` shows the next elapse |
| sysctl | `sysctl -n <key>` equals the intended value |
| fstab | `findmnt /target`, and only mount the new entry explicitly |
| niri | `niri validate`, then reload the compositor config if supported |
| networking | `nmcli con show`, `ip -br a`, reachability from outside |

## Failure modes

- Validated the wrong file: package default still wins over your edit. Use
  `systemctl cat` and `systemd-analyze cat-config`.
- Treated a permission error as a parse error (sshd, visudo).
- Restarted a service that was healthy and lost the previous state; prefer
  reload, and keep the backout ready.
- Fixed syntax but not semantics: values accepted but ignored because they are
  in the wrong section, scope, or drop-in.
- Verified with `is-active` only. Active means the process started, not that
  it works.
