# Claude Code Context: NixOS on ChromeOS (Baguette/Crostini)

This is a NixOS system running inside ChromeOS via Baguette (containerless VM) or legacy LXC container.

## System Rebuild

```bash
# Rebuild and switch (from inside the VM)
sudo nixos-rebuild switch --flake /etc/nixos#baguette-nixos

# Or for LXC container
sudo nixos-rebuild switch --flake /etc/nixos#lxc-nixos
```

The flake source is typically at `/etc/nixos` or wherever you've cloned it.

## Key Paths

- `/opt/google/cros-containers/bin/` - ChromeOS integration binaries (garcon, sommelier, vshd, maitred)
- `/run/current-system/` - Current NixOS generation
- `~/.config/` - User config (XDG standard)

## ChromeOS Integration

### Display (X11/Wayland)
- `sommelier` handles X11/Wayland forwarding to ChromeOS
- `DISPLAY` and `WAYLAND_DISPLAY` are set automatically via sommelier services
- GUI apps "just work" - they appear as ChromeOS windows

### Clipboard
- Use `wl-copy` / `wl-paste` for clipboard operations
- Clipboard is shared with ChromeOS automatically

### URLs/Files
- `xdg-open <url>` opens in ChromeOS browser
- `garcon-url-handler` handles URL forwarding
- Files in `/mnt/chromeos/` are shared with ChromeOS (if file sharing enabled)

### Ports
- `cros-port-listener` forwards ports to ChromeOS automatically
- localhost services are accessible from ChromeOS

### Notifications
- `cros-notificationd` forwards notifications to ChromeOS notification center

## Baguette-Specific Notes

- Baguette is a "containerless" VM (ChromeOS >= 143)
- Filesystem is btrfs on `/dev/vdb`
- DNS comes from host (`/run/resolv.conf`)
- No kernel module loading (host kernel is used)
- `vmc` commands from crosh manage the VM

### crosh Commands (from ChromeOS)

```bash
# Open crosh: Ctrl+Alt+T

# Start the VM
vmc start --vm-type BAGUETTE baguette

# New shell session
vsh baguette penguin

# Stop the VM
vmc stop baguette

# List VMs
vmc list
```

## Installing Packages

**When asked to install a package, clarify which persistence level the user wants:**

There are three ways to install packages, each with different persistence:

### 1. Session-only (ephemeral)
Available immediately but lost on shell exit/re-entry:
```bash
nix-shell -p openjdk

# Or for a more integrated experience:
nix shell nixpkgs#openjdk
```
**Use when**: Testing, one-off tasks, temporary needs.

### 2. User profile (survives reboot, lost on VM rebuild)
Persists across shell sessions and reboots, but not if VM is destroyed/recreated:
```bash
nix profile install nixpkgs#openjdk

# List installed:
nix profile list

# Remove:
nix profile remove openjdk
```
**Use when**: User wants a package now without editing config, accepts it won't survive a VM rebuild.

### 3. Declarative (persists into image)
Add to `configuration.nix`, rebuild, and optionally push to GitHub for image rebuild:
```bash
# Edit /etc/nixos/configuration.nix, add to environment.systemPackages:
#   openjdk

# Apply locally (survives reboots, lost on VM destroy/recreate):
sudo nixos-rebuild switch --flake /etc/nixos#baguette-nixos

# To persist into the image for future VM creates:
# 1. Commit and push changes to GitHub fork
# 2. Wait for GitHub Actions to build new image
# 3. Download artifact and recreate VM with new image
```
**Use when**: Package should be part of the base system permanently.

### Summary Table

| Method | Survives shell exit | Survives reboot | Survives VM rebuild |
|--------|---------------------|-----------------|---------------------|
| `nix-shell -p` | No | No | No |
| `nix profile install` | Yes | Yes | No |
| `configuration.nix` + local rebuild | Yes | Yes | No |
| `configuration.nix` + push + new image | Yes | Yes | Yes |

### Update system
```bash
cd /etc/nixos
nix flake update
sudo nixos-rebuild switch --flake .#baguette-nixos
```

### Check service status
```bash
# System services
systemctl status sommelier@0 garcon maitred vshd

# User services (sommelier runs per-user)
systemctl --user status sommelier@0 sommelier-x@0 garcon
```

## Troubleshooting

### GUI apps not working
```bash
# Check sommelier
systemctl --user status sommelier@0 sommelier-x@0

# Verify DISPLAY is set
echo $DISPLAY $WAYLAND_DISPLAY
```

### Clipboard not working
```bash
# Test with wl-paste
echo "test" | wl-copy
wl-paste
```

### Network issues
```bash
# DNS comes from host
cat /run/resolv.conf

# Check DHCP
systemctl status dhcpcd
```

## Architecture

- `baguette.nix` - Baguette VM module (btrfs image, boot config, systemd services)
- `crostini.nix` - Legacy LXC container module
- `common.nix` - Shared ChromeOS integration (sommelier, garcon, clipboard tools)
- `configuration.nix` - User configuration (packages, users)
- `flake.nix` - Flake definition with build targets

## Upstream References

- [nixos-crostini repo](https://github.com/aldur/nixos-crostini)
- [Baguette blog post](https://aldur.blog/nixos-baguette)
- [LXC blog post](https://aldur.blog/nixos-crostini)
- [ChromeOS containers docs](https://www.chromium.org/chromium-os/developer-library/guides/containers/containers-and-vms/)
