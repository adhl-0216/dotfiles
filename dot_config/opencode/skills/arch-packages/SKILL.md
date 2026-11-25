---
name: Arch packages
description: Install, remove, upgrade, downgrade, or audit packages with pacman and paru on this Arch system. Use before any package operation, when resolving dependency, conflict, disk, lock, or signature errors, or when inspecting ownership, integrity, orphans, and the package cache.
---

# Arch packages

Local state (verified): pacman 7.1.0, paru 2.2.0. Repositories are
`cachyos-v3`, `cachyos-core-v3`, `cachyos-extra-v3`, `cachyos`, `core`,
`extra`, `multilib`. `/etc/pacman.conf` sets `IgnorePkg = spotify` and
`ParallelDownloads = 10`. The cache is `/var/cache/pacman/pkg`, populated with
`*.pkg.tar.zst`.

The agent prompt prefers `paru` for general use. Use `pacman` directly when
paru adds nothing: queries (`-Q*`), integrity checks, `-Dk`, `-U` upgrades, and
raw cache work.

## Inspect before acting

```bash
pacman -Q <pkg>          # is it installed, and at what version
pacman -Qi <pkg>         # version, depends on, required by, reason
pacman -Qo /path/file    # which package owns a file
pacman -Ql <pkg>         # files the package owns
pacman -Qkk <pkg>        # file presence and properties (verified format)
pacman -Qm               # foreign: AUR or manually installed
pacman -Qdtq             # orphaned dependencies, quiet
pacman -Si <pkg>         # repository metadata
paru -Si <pkg>           # falls back to the AUR (verified)
pacman -Dk               # database consistency (verified: no errors)
```

`pacman -T` performs a dependency test. `pacman -Qkk` is the cheapest way to
prove a package's files are still intact after suspicious changes.

## Upgrade policy

- Full upgrades only: `paru -Syu`. Arch does not support partial upgrades;
  `pacman -Sy <pkg>` mixes a new sync database with old installed libraries and
  is explicitly listed as unsupported on the Arch Wiki (System maintenance,
  "Partial upgrades are unsupported", retrieved 2026-11-16).
- Check pending updates without syncing the database: `checkupdates`
  (verified) or `paru -Qu`.
- Read news before large upgrades: `paru -Pw`.
- If `-Syu` fails after the sync half, resolve the error and finish the upgrade
  before any other package operation. Do not "fix" missing libraries with
  symlinks.
- Reboot when core packages change (kernel, glibc, systemd, NVIDIA). A running
  process keeps the old library until restarted.
- `IgnorePkg = spotify` is configured; `paru -Qu` marks such packages
  `[ignored]`. Do not remove the ignore without asking.

## AUR

- Fetch and review before building: `paru -Gp <pkg>` prints the PKGBUILD to
  stdout (verified), `paru -G <pkg>` clones it.
- Treat every PKGBUILD as untrusted. Check `source=`, `url`, build functions,
  and install scripts. `--review` forces review; `--skipreview` disables it
  (both present in paru 2.2 `--help`).
- After a soname bump, rebuild foreign packages:
  `paru -S --rebuild <pkg>` (flag verified).
- Be aware that AUR packages are built locally, so they are usually absent from
  the binary package cache and cannot be downgraded with `pacman -U` alone.

## Remove

```bash
paru -Rns <pkg>          # remove with unneeded dependencies and config
pacman -Qdtq             # confirm no new orphans
```

Never use `-Rdd`: skipping dependency checks can remove a critical provider.
Check `pacman -Qi <pkg>` "Required By" before removing anything that looks
foundational.

## Signatures and keyring

On `invalid or corrupted package (PGP signature)`:

1. Confirm the mirror is sane and the system is otherwise upgradeable.
2. Ensure `archlinux-keyring` is current (it is part of a normal full upgrade).
3. If individual keys are still unknown, follow the Arch Wiki
   `pacman/Package signing` troubleshooting; do not disable signature checking.

## Disk, lock, and conflict errors

- **No space left:** `df -h /`, `du -sh /var/cache/pacman/pkg`, then
  `paccache -r` (`-k <num>` to keep a specific count, verified).
- **Locked database:** confirm no pacman or paru is running with
  `pgrep -a pacman`, then remove `/var/lib/pacman/db.lck`. Never delete the lock
  while an operation is live.
- **File exists in filesystem:** identify the owner with `pacman -Qo`, then
  decide between removing the stray file and a targeted `--overwrite`. The Arch
  Wiki advises using `--overwrite` only when developers explicitly recommend it.

## Downgrade

```bash
pacman -U /var/cache/pacman/pkg/<pkg>-<version>-<arch>.pkg.tar.zst
```

Check that dependencies still resolve afterwards. Full backout procedure and
AUR rebuild handling are in `change-backout`.

## Verify after the operation

```bash
pacman -Q <pkg>
pacman -Qkk <pkg>
command -v <binary>
systemctl is-active <unit>          # if the package ships a service
journalctl -b -p err -n 30 --no-pager
```

A successful install does not prove the package works; run the binary or check
the service.
