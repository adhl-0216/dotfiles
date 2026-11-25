---
name: NVIDIA Wayland
description: Diagnose and fix NVIDIA graphics, hybrid AMD/NVIDIA offload, or Wayland compositor problems on this machine. Use for black screens, missing outputs, nvidia-smi failures, offload not working, suspend/resume GPU faults, or application-specific rendering errors.
---

# NVIDIA Wayland

## Verified local state

- Hybrid graphics: AMD Renoir iGPU (`amdgpu` loaded) plus NVIDIA GeForce RTX
  3060 Laptop GPU.
- Driver 620.70.06, **open kernel modules**: `/proc/driver/nvidia/version`
  reports `NVIDIA UNIX Open Kernel Module`. Userland: `nvidia-utils`,
  `lib32-nvidia-utils`, `nvidia-prime`, `libva-nvidia-driver`.
- Kernel packages: `linux-cachyos-nvidia-open` and
  `linux-cachyos-lts-nvidia-open`. The module is built for the kernel package,
  so a kernel update without the matching module rebuild breaks graphics.
- At the time this was written the running kernel lagged the installed one, so
  `modinfo nvidia` could not resolve the loaded module. Treat that as a pending
  reboot, not a driver fault; see the failure modes below.
- `nvidia_drm.modeset=Y` and `nvidia_drm.fbdev=Y` are active.
- Session: niri 26.04 on Wayland (`XDG_SESSION_TYPE=wayland`,
  `WAYLAND_DISPLAY=wayland-1`, `Desktop=niri`).
- DRM nodes: `/dev/dri/card1`, `card2`, `renderD128`, `renderD129`.
- `nvidia-suspend`, `nvidia-resume`, `nvidia-hibernate`,
  `nvidia-suspend-then-hibernate` are installed but **disabled**.
  `nvidia-powerd` is enabled.

Do not re-derive these facts; re-check only the specific value under suspicion.

## Diagnose by layer

Work outward. Confirm the layer below before blaming the layer above.

### 1. Kernel module

```bash
lsmod | grep -E 'nvidia|amdgpu'
cat /proc/driver/nvidia/version
journalctl -k -b -g 'NVRM|nvidia' -n 50 --no-pager    # -g verified
```

Expected: `nvidia`, `nvidia_modeset`, `nvidia_drm`, `nvidia_uvm`, `amdgpu`.
If `nvidia_drm` is absent, suspend/resume and Wayland are both suspect; the
fault is below the compositor.

### 2. Device and DRM

```bash
nvidia-smi
cat /sys/module/nvidia_drm/parameters/modeset
cat /sys/module/nvidia_drm/parameters/fbdev
ls -l /dev/dri
```

Verified healthy output on this machine: `nvidia-smi` reports
`NVIDIA GeForce RTX 3060 Laptop GPU, 620.70.06, 6144 MiB`.

`nvidia-smi: No devices were found` means the kernel module is not loaded or the
driver did not bind the GPU, not that the GPU is dead.

### 3. Userspace GL/Vulkan/EGL

```bash
eglinfo -B                    # EGL/GBM, picks the default DRM device
glxinfo -B                    # GLX via XWayland (DISPLAY is :0 here)
prime-run glxinfo -B          # offload path
```

Verified on this machine: `prime-run glxinfo -B` reports
`NVIDIA GeForce RTX 3060 Laptop GPU/PCIe/SSE2`. `prime-run eglinfo -B` still
reports the AMD renderer because EGL/GBM selects the default DRM device; that
is not evidence that offload is broken. Use the GLX check, or confirm the
process appears in the `nvidia-smi` process list.

`eglinfo` is installed; `vulkaninfo` is **not**, so do not assume it.

`_amdgpu_device_initialize: amdgpu_query_info(ACCEL_WORKING) failed (-13)` was
observed in `eglinfo` output on this machine. It is a probe from a context
without the needed permissions; correlate it with a real render failure before
treating it as the cause.

### 4. Compositor

```bash
niri validate                          # config syntax, verified
niri msg outputs                       # live outputs, verified subcommand
niri msg version
journalctl --user -b -p warning -n 50 --no-pager
```

`niri validate` only proves the config parses. `niri msg outputs` proves the
compositor enumerated at least one output.

### 5. Application

Confirm the app is really on Wayland, not XWayland:

```bash
echo "$XDG_SESSION_TYPE"
```

niri's `environment {}` block currently sets `XDG_CURRENT_DESKTOP`,
`XDG_SESSION_TYPE`, `ELECTRON_OZONE_PLATFORM_HINT=auto`, `QT_QPA_PLATFORM=wayland`,
`QT_QPA_PLATFORMTHEME`, and `QT_WAYLAND_DISABLE_WINDOWDECORATION`. It sets no
NVIDIA-specific variables, which is correct for a hybrid setup.

## Hybrid offload

`/usr/bin/prime-run` (from `nvidia-prime`, verified contents) sets:

```
__NV_PRIME_RENDER_OFFLOAD=1
__VK_LAYER_NV_optimus=NVIDIA_only
__GLX_VENDOR_LIBRARY_NAME=nvidia
```

Use it per application: `prime-run <command>`. Do **not** export these globally
in the compositor environment. The iGPU should drive the desktop; forcing the
dGPU for everything costs battery and can break suspend.

## Common faults and checks

- **Black screen or no outputs after a driver update.** Check modeset/fbdev
  parameters and `niri msg outputs`; switch to a TTY and boot the LTS kernel
  (installed as `linux-cachyos-lts-nvidia-open`).
- **Module not resolvable after a kernel update.** If `modinfo nvidia` fails
  while `lsmod` still shows the module loaded, compare `uname -r` with the
  directories in `/usr/lib/modules`. When they differ, the kernel was updated
  without a reboot and the running kernel's module tree is gone; modules load
  fine but cannot be inspected or rebuilt until you boot the installed kernel
  (or the LTS entry). Do not mix `nvidia` and `nvidia-open` packages.
- **Open versus proprietary mismatch.** `pacman -Q | grep -E 'nvidia|linux-.*nvidia'`
  should show a consistent set. The kernel module string must say "Open Kernel
  Module" on this machine.
- **Suspend/resume loses the GPU.** `nvidia-suspend.service` and
  `nvidia-resume.service` exist but are disabled; both run
  `/usr/bin/nvidia-sleep.sh` (verified with `systemctl cat`). There is no local
  man page for these units. Enabling them is a planned change, not a quick
  toggle.
- **App renders on the wrong GPU.** Compare `glxinfo -B` with and without
  `prime-run`, and confirm the app is not an XWayland client. `eglinfo` does not
  reflect offload here; see the note above.
- **NVRM errors in the journal.** `journalctl -k -b -g NVRM`; correlate the
  timestamp with the failure before changing anything.
- **`nvidia-powerd` failing.** It provides Dynamic Boost and is enabled here;
  a failure affects performance, not rendering.

## Recovery

1. `Ctrl+Alt+F3` to a TTY. Wayland compositors do not recover a dead GPU.
2. Boot the LTS kernel from Limine. `linux-cachyos-lts-nvidia-open` is
   installed, but `/boot` entries are not readable unprivileged here, so confirm
   the menu entry exists before depending on it (use `zenity-sudo` for root).
3. Downgrade the driver from the package cache (see `change-backout`).
4. Regenerate initramfs and boot entries with `limine-mkinitcpio` or
   `limine-update` after any kernel or driver change. The `mkinitcpio` wrapper
   in `/usr/local/bin` warns that plain `mkinitcpio -P` does not update Limine
   entries.
5. Never hand-edit `/boot`.

## Verify a fix

```bash
nvidia-smi                                   # GPU enumerated, version matches
eglinfo -B                                   # EGL renders
prime-run glxinfo -B                         # NVIDIA renderer under offload
niri msg outputs                             # outputs present
journalctl -b -p err -g NVRM -n 20 --no-pager
lsmod | grep nvidia_drm
```

Graphics fixes are only verified when a real application renders on the
expected GPU. `nvidia-smi` alone is a necessary but not sufficient check.
