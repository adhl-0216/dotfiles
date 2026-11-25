---
name: systemd units
description: Create, override, debug, enable, mask, or time systemd units. Use when a service fails or crash-loops, when a config override or drop-in is needed, when writing a service or timer, or when changing enable, mask, or runtime state.
---

# systemd units

Local install is systemd 262.2-1. Vendor units ship in
`/usr/lib/systemd/system`, administrator overrides belong in
`/etc/systemd/system`, and runtime state lives in `/run/systemd/system`. Never
edit vendor units: package upgrades replace them. Confirm the real search order
with `systemd-analyze unit-paths` (verified).

## Read the effective unit before changing it

```bash
systemctl cat <unit>                                 # merged view, all drop-ins
systemctl show <unit> -p FragmentPath,ActiveState,SubState,CanReload,User,ExecStart,ExecMainStatus,Result
systemd-analyze verify /usr/lib/systemd/system/<unit>   # unprivileged, verified
```

`systemctl cat` is the only reliable way to see what systemd will actually load;
a vendor file plus two drop-ins can look nothing like any single file.

## Overrides

```bash
systemctl edit <unit>              # /etc/systemd/system/<unit>.d/override.conf
systemctl edit --runtime <unit>    # /run/... , discarded at reboot
systemctl edit --full <unit>       # copies the whole unit into /etc
systemctl edit --drop-in=NAME <unit>
```

- Prefer a drop-in over `--full`: smaller diff, survives vendor updates.
- `--runtime` is for experiments. Per `man systemctl`, it cannot temporarily
  edit a unit that lives in `/etc/`, because `/etc` takes precedence over
  `/run/`.
- `systemctl edit` reloads the manager automatically. A hand-written unit file
  does not: run `systemctl daemon-reload`.
- `systemctl revert <unit>` deletes local overrides and returns to the vendor
  unit; it also discards intentional customisation.

## Change cycle

1. Back up (see `change-backout`).
2. Edit through `systemctl edit`.
3. `systemd-analyze verify /etc/systemd/system/<unit>` (or the vendor path).
4. `systemctl daemon-reload` if you wrote files directly.
5. `systemctl restart <unit>`.
6. `systemctl status <unit> --no-pager` and
   `journalctl -u <unit> -b -n 50 --no-pager`.
7. Check the function, not just `is-active`.

## Timers

```bash
systemctl list-timers --all
systemd-analyze calendar '*-*-* 04:00:00'    # validate OnCalendar, verified
systemctl start <name>.timer                 # after editing
systemctl enable --now <name>.timer
```

- A timer activates the service of the same base name, so the pair must match.
- `Persistent=true` runs a missed job after boot; without it the schedule is
  skipped.
- `list-timers` is the only real proof of the next elapse; a syntactically valid
  `OnCalendar` can still be wrong.
- A oneshot service with `RemainAfterExit=no` shows `inactive (dead)` after a
  successful run. That is success, not failure; check `ExecMainStatus`.

## Enable, start, mask

| Goal | Command |
|---|---|
| enable at boot and start now | `systemctl enable --now <unit>` |
| stop but keep enabled | `systemctl stop <unit>` |
| disable at boot and stop | `systemctl disable --now <unit>` |
| block all starts | `systemctl mask <unit>` |
| block until reboot only | `systemctl mask --runtime <unit>` |
| clear a start-limit lockout | `systemctl reset-failed <unit>` |

`disable` does not stop a running unit, and `stop` does not disable it. State
this explicitly in plans so the two are not conflated.

## Failure patterns

- **Unit not found.** Wrong suffix (`foo` versus `foo.service`), or the file is
  outside every search path. `systemd-analyze unit-paths` lists the paths.
- **`start-limit-hit`.** Crash loop; fix the cause, then `reset-failed`.
  Raising `StartLimitBurst` hides a bug.
- **Environment missing.** Units do not inherit your shell. Use `Environment=`
  or `EnvironmentFile=`; check with `systemctl show -p Environment <unit>`.
- **Ordering.** `After=` only orders; it does not require. Use `Requires=` or
  `Wants=` for dependencies, and verify the graph with
  `systemd-analyze verify`.
- **Sandboxing.** `ProtectSystem=`, `PrivateTmp=`, `NoNewPrivileges=`,
  `ProtectHome=` can break writes that worked before. Check
  `systemd-analyze security <unit>` and the journal for `Permission denied`.
- **User units.** Use `systemctl --user`, `journalctl --user-unit <unit>`, and
  `loginctl enable-linger <user>` if the unit must run without a login.

## Verification

```bash
systemctl is-active <unit>
systemctl show <unit> -p ActiveState,SubState,Result,ExecMainStatus
journalctl -u <unit> -b -p warning -n 50 --no-pager
systemctl --failed --no-legend
```

`Result=core-dump` or a non-zero `ExecMainStatus` means the unit ran and failed,
even when `SubState` looks idle.
