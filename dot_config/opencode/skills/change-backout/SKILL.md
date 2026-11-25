---
name: Change backout
description: Record a restore point and a concrete rollback path before changing a system. Use for any Medium, High, or Critical change - config edits, service units, packages, kernel or initramfs, bootloader, networking, authentication, permissions, or storage.
---

# Change backout

The agent prompt requires a backout method in every plan and, for High and
Critical changes, an established way to reach the previous known-good state.
This skill supplies the mechanisms. Execute backout in the reverse order of the
change, and verify the restore rather than assuming it.

## Before changing anything

Capture the pre-change state. This is the actual restore point; a snapshot or
copy made afterwards is not a backout.

```bash
# Files: content, mode, owner, ACLs, immutable flags
cp -a --preserve=all /etc/foo.conf /etc/foo.conf.bak.$(date +%Y%m%dT%H%M%S)
sha256sum /etc/foo.conf
stat -c '%a %U:%G %n' /etc/foo.conf
getfacl -p /etc/foo.conf
lsattr /etc/foo.conf

# Packages: version and file integrity baseline
pacman -Q <pkg>
pacman -Qkk <pkg>
pacman -Dk

# Services: effective unit and state
systemctl show <unit> -p FragmentPath,ActiveState,SubState,CanReload
systemctl status <unit> --no-pager
```

Write the exact restore command into the plan before running the change. If you
cannot state how to undo it, you are not ready to do it.

## Restore mechanisms, cheapest first

| Mechanism | Use for | Cost |
|---|---|---|
| Copy the backup back | single config file, live service | seconds |
| Delete the drop-in, `systemctl daemon-reload` | unit override | seconds |
| `systemctl edit --runtime` from the start | experimental unit change | lost at reboot |
| Package downgrade from cache | bad package update | minutes |
| `snapper undochange` | specific files changed in a window | minutes |
| `snapper rollback` | whole-system regression | reboot |
| Boot a previous snapshot or kernel entry | unbootable system | reboot |

### Files and units

```bash
cp -a --preserve=all /etc/foo.conf.bak.20261116T2200 /etc/foo.conf
rm /etc/systemd/system/<unit>.d/override.conf
systemctl daemon-reload
```

`systemctl edit --runtime` writes under `/run` and is discarded on reboot. Man
`systemctl` documents an important limit: a runtime edit cannot override a unit
that lives in `/etc/`, because `/etc` takes precedence over `/run/`.

`systemctl revert <unit>` removes all local overrides and returns to the vendor
unit, but it discards intentional customisation too. Use it only when that is
the goal.

### Packages

```bash
pacman -U /var/cache/pacman/pkg/<pkg>-<version>-<arch>.pkg.tar.zst
```

The cache is populated on this machine. Check that the cached version's
dependencies still resolve; a downgrade can leave a library mismatch. AUR
packages are not in the cache and must be rebuilt:

```bash
paru -S --rebuild <pkg>
```

### Snapshots (btrfs root, snapper config `root`)

```bash
# Create a restore point (needs root; uses sudo/zenity-sudo if no TTY)
snapper -c root create -d "pre-<change>" -u "reason=<change>" -p

# List and confirm (needs root)
snapper -c root list

# Restore selected files from a snapshot window
snapper -c root undochange <pre>..<post> /etc/foo.conf
```

`undochange` edits files in place; it is not a full rollback.

`snapper rollback [number]` creates two new snapshots and sets a read-write
snapshot as the default subvolume, so it takes effect on the next boot (man
`snapper`). `limine-snapper-sync` is installed here and publishes snapshot
entries in the Limine menu, which is the recovery path for a non-booting system.

Do not assume snapshots are being taken. Confirm with `snapper -c root list`
before relying on one.

### Boot assets

Kernel, initramfs, and boot entries are High risk. Keep the previous kernel
installed and a known-good menu entry before regenerating anything. Boot assets
here are managed by Limine:

```bash
limine-mkinitcpio     # regenerate initramfs and Limine entries
limine-update
```

`/usr/local/bin/mkinitcpio` is a wrapper that warns you to use the Limine
commands above. Do not hand-edit `/boot`.

## Safety nets for High and Critical changes

- Keep a working second session open before touching networking, display, or
  authentication: a TTY on another VT (`Ctrl+Alt+F3`) or a second SSH login.
  `tmux` helps, but only if its server outlives the session you are restarting;
  do not treat it as a guaranteed lifeline.
- Schedule an automatic revert so a lockout heals itself:

  ```bash
  systemd-run --on-active=10min --unit=auto-revert /usr/local/sbin/revert-foo
  # cancel after verifying:
  systemctl stop auto-revert.timer
  ```

  `--on-active` is documented in `man systemd-run`.
- Sudoers: keep a root shell open and `visudo` running until a new login is
  verified. Never recurse permissions across `/etc`.
- Storage: verify free space and a restorable snapshot before destructive
  operations. `snapper rollback` needs the snapshot subvolume to exist.

## Verify the restore

```bash
sha256sum /etc/foo.conf                  # compare with the recorded hash
pacman -Qkk <pkg>
systemctl --failed --no-legend
journalctl -b -p err -n 30 --no-pager
```

Then repeat the functional check from the original change. A restore that
returns the file but not the behaviour is not a backout.

## Anti-patterns

- Backing up after the edit, or overwriting the only backup on the second
  attempt.
- `cp` without `-a` on a config with restrictive permissions or an ACL.
- Treating `rm`, `truncate`, or `dd` as reversible.
- Planning a rollback that requires a reboot when the change must not reboot.
- Assuming a snapshot exists because snapper is installed.
