#!/bin/bash
# Artix Linux OpenRC Installer — post-install automation
# Usage: ./install.sh [--dry-run] [--no-packages] [--no-services] [--hardware]
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$DOTFILES/pkg"
SYSTEM_DIR="$DOTFILES/system"
LOGFILE="/tmp/artix-install-$(date +%Y%m%d-%H%M%S).log"

# --- Flags ---
DRY_RUN=0
NO_PACKAGES=0
NO_SERVICES=0
HARDWARE=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)      DRY_RUN=1 ;;
        --no-packages)  NO_PACKAGES=1 ;;
        --no-services)  NO_SERVICES=1 ;;
        --hardware)     HARDWARE=1 ;;
        -h|--help)      sed -n '2,/^$/{ s/^# //; s/^#//; p }' "$0"; exit 0 ;;
        *) echo "Unknown flag: $arg"; exit 1 ;;
    esac
done

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOGFILE"; }
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        log "DRY-RUN: $*"
        return 0
    fi
    "$@" >> "$LOGFILE" 2>&1
}

# --- Check environment ---
if [ "$(id -u)" -eq 0 ]; then
    echo "Jangan jalankan sebagai root. Script akan minta sudo saat dibutuhkan."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    echo "Bukan sistem Arch/Artix. Keluar."
    exit 1
fi

if [ ! -f /etc/openrc ]; then
    echo "WARNING: OpenRC tidak terdeteksi. Beberapa fitur mungkin tidak bekerja."
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Artix Linux OpenRC Installer               ║"
echo "║   Log: $LOGFILE"
echo "╚══════════════════════════════════════════════╝"
echo ""

# =========================================================
# 1. SYNC KEYRING & MIRROR
# =========================================================
log "=== Sync pacman keyring ==="
run sudo pacman -Sy --noconfirm archlinux-keyring artix-keyring
run sudo pacman -Sy --noconfirm

# =========================================================
# 2. INSTALL NATIVE PACKAGES
# =========================================================
if [ "$NO_PACKAGES" -eq 0 ] && [ -f "$PKG_DIR/native.txt" ]; then
    log "=== Installing native packages ==="
    # Filter: skip empty lines, comments, base/kernel (handled by ISO)
    NATIVE_PKGS=$(grep -v '^#' "$PKG_DIR/native.txt" | grep -v '^$' | \
        grep -v '^base$' | grep -v '^base-devel$' | \
        grep -v '^linux$' | grep -v '^linux-headers$' | \
        grep -v '^linux-firmware$' | grep -v '^intel-ucode$')

    COUNT=$(echo "$NATIVE_PKGS" | wc -l)
    log "  $COUNT native packages to install"

    if [ "$DRY_RUN" -eq 0 ]; then
        echo "$NATIVE_PKGS" | sudo pacman -S --needed --noconfirm -
    else
        log "DRY-RUN: Would install $COUNT native packages"
    fi
fi

# =========================================================
# 3. INSTALL YAY (AUR HELPER)
# =========================================================
if [ "$NO_PACKAGES" -eq 0 ]; then
    if ! command -v yay &>/dev/null; then
        log "=== Installing yay ==="
        if [ "$DRY_RUN" -eq 0 ]; then
            cd /tmp
            git clone https://aur.archlinux.org/yay-bin.git
            cd yay-bin
            makepkg -si --noconfirm
            cd "$DOTFILES"
            rm -rf /tmp/yay-bin
        else
            log "DRY-RUN: Would install yay"
        fi
    else
        log "  yay already installed"
    fi
fi

# =========================================================
# 4. INSTALL AUR PACKAGES
# =========================================================
if [ "$NO_PACKAGES" -eq 0 ] && [ -f "$PKG_DIR/aur.txt" ]; then
    log "=== Installing AUR packages ==="
    AUR_PKGS=$(grep -v '^#' "$PKG_DIR/aur.txt" | grep -v '^$' | grep -v '^yay$')
    COUNT=$(echo "$AUR_PKGS" | grep -c . || true)

    if [ "$COUNT" -gt 0 ] && command -v yay &>/dev/null; then
        log "  $COUNT AUR packages to install"
        if [ "$DRY_RUN" -eq 0 ]; then
            echo "$AUR_PKGS" | yay -S --needed --noconfirm -
        else
            log "DRY-RUN: Would install $COUNT AUR packages"
        fi
    fi
fi

# =========================================================
# 5. STOW DOTFILES
# =========================================================
log "=== Installing dotfiles via stow ==="
STOW_PACKAGES="bashrc i3 kitty picom i3status neofetch ranger htop btop cava gtk mimeapps opencode"
for pkg in $STOW_PACKAGES; do
    if [ -d "$DOTFILES/$pkg" ]; then
        log "  stow $pkg"
        run stow -d "$DOTFILES" -t "$HOME" -v "$pkg"
    fi
done

# =========================================================
# 6. COPY SCRIPTS
# =========================================================
log "=== Copying scripts ==="
SCRIPTS_DIR="$HOME/doc/kodingan/skrip"
mkdir -p "$SCRIPTS_DIR"
if [ -d "$DOTFILES/scripts" ]; then
    run cp -r "$DOTFILES/scripts/"* "$SCRIPTS_DIR/"
    run chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
    log "  scripts → $SCRIPTS_DIR"
fi

# =========================================================
# 7. SYSTEM CONFIGS (need sudo)
# =========================================================
log "=== Installing system configs ==="

# X11 configs
if [ -d "$SYSTEM_DIR/xorg/xorg.conf.d" ]; then
    log "  X11 xorg.conf.d"
    run sudo cp -n "$SYSTEM_DIR/xorg/xorg.conf.d/"* /etc/X11/xorg.conf.d/ 2>/dev/null || true
fi

# Hardware-specific configs (opt-in)
if [ "$HARDWARE" -eq 1 ] && [ -d "$PKG_DIR/hardware" ]; then
    log "  Hardware-specific configs"
    for f in "$PKG_DIR/hardware/"*; do
        [ -f "$f" ] || continue
        fname="$(basename "$f")"
        case "$fname" in
            *.conf) run sudo cp -n "$f" /etc/X11/xorg.conf.d/ ;;
            *)      run sudo cp -n "$f" /etc/ ;;
        esac
    done
fi

# Modprobe
if [ -d "$SYSTEM_DIR/modprobe.d" ]; then
    log "  modprobe.d"
    run sudo cp -n "$SYSTEM_DIR/modprobe.d/"* /etc/modprobe.d/ 2>/dev/null || true
fi

# Modules load
if [ -d "$SYSTEM_DIR/modules-load.d" ]; then
    log "  modules-load.d"
    run sudo cp -n "$SYSTEM_DIR/modules-load.d/"* /etc/modules-load.d/ 2>/dev/null || true
fi

# Udev rules
if [ -d "$SYSTEM_DIR/udev/rules.d" ]; then
    log "  udev rules"
    run sudo cp -n "$SYSTEM_DIR/udev/rules.d/"* /etc/udev/rules.d/ 2>/dev/null || true
fi

# Security: nftables, sysctl, audit, polkit, fail2ban
[ -f "$SYSTEM_DIR/nftables/nftables.conf" ] && log "  nftables" && run sudo cp -n "$SYSTEM_DIR/nftables/nftables.conf" /etc/nftables.conf
[ -d "$SYSTEM_DIR/sysctl.d" ] && log "  sysctl.d" && run sudo cp -n "$SYSTEM_DIR/sysctl.d/"* /etc/sysctl.d/ 2>/dev/null
[ -d "$SYSTEM_DIR/audit/rules.d" ] && log "  audit rules" && run sudo cp -n "$SYSTEM_DIR/audit/rules.d/"* /etc/audit/rules.d/ 2>/dev/null
[ -d "$SYSTEM_DIR/polkit/rules.d" ] && log "  polkit rules" && run sudo cp -n "$SYSTEM_DIR/polkit/rules.d/"* /etc/polkit-1/rules.d/ 2>/dev/null
[ -f "$SYSTEM_DIR/fail2ban/jail.local" ] && log "  fail2ban" && run sudo cp -n "$SYSTEM_DIR/fail2ban/jail.local" /etc/fail2ban/

# conf.d files (only copy if exists in dotfiles)
for f in "$SYSTEM_DIR/conf.d/"*; do
    [ -f "$f" ] || continue
    fname="$(basename "$f")"
    log "  conf.d/$fname"
    run sudo cp -n "$f" /etc/conf.d/
done

# Pacman config
[ -f "$SYSTEM_DIR/pacman/makepkg.conf" ] && log "  makepkg.conf" && run sudo cp -n "$SYSTEM_DIR/pacman/makepkg.conf" /etc/

# =========================================================
# 8. ENABLE OPENRC SERVICES
# =========================================================
if [ "$NO_SERVICES" -eq 0 ] && [ -f "$SYSTEM_DIR/openrc/services.txt" ]; then
    log "=== Enabling OpenRC services ==="

    # Skip broken symlinks and sysinit/boot (managed by base install)
    grep -v '^#' "$SYSTEM_DIR/openrc/services.txt" | grep -v '^$' | \
    grep -v 'SKIP(broken)' | \
    grep -v '^sysinit|' | \
    grep -v '^boot|' | \
    while IFS='|' read -r level svc; do
        log "  rc-update add $svc $level"
        run sudo rc-update add "$svc" "$level" 2>/dev/null || true
    done

    # Ensure critical services are enabled
    for svc in NetworkManager dbus fail2ban ntpd docker; do
        if ! rc-update show default | grep -q "$svc"; then
            log "  [force] rc-update add $svc default"
            run sudo rc-update add "$svc" default 2>/dev/null || true
        fi
    done
fi

# =========================================================
# 9. RELOAD
# =========================================================
log "=== Reloading configs ==="
run sudo sysctl --system 2>/dev/null || true
[ -f /etc/nftables.conf ] && run sudo rc-service nftables restart 2>/dev/null || true
run sudo rc-service fail2ban restart 2>/dev/null || true

# =========================================================
# DONE
# =========================================================
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Selesai! Restart needed: reboot            ║"
echo "║   Log: $LOGFILE"
echo "╚══════════════════════════════════════════════╝"
echo ""
[ "$DRY_RUN" -eq 1 ] && echo "Mode DRY-RUN — tidak ada perubahan yang dibuat."
echo "Restart i3: Mod+Shift+r"
