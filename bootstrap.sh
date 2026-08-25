#!/bin/bash
# Bootstrap untuk laptop baru — jalankan SEKALI setelah install Artix OpenRC
# Usage: curl -fsSL <raw-github-url>/bootstrap.sh | bash
#   atau: scp bootstrap.sh user@new-laptop:~/ && bash bootstrap.sh
set -euo pipefail

DOTFILES_REPO="https://github.com/mpuss37/artix-openrc-installer.git"
DOTFILES_DIR="$HOME/dotfiles"

echo "╔══════════════════════════════════════════════╗"
echo "║   Artix Linux Bootstrap                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# --- Pre-check ---
if [ "$(id -u)" -eq 0 ]; then
    echo "Jangan jalankan sebagai root."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    echo "Bukan sistem Arch/Artix."
    exit 1
fi

if ! grep -q "openrc" /proc/1/comm 2>/dev/null; then
    echo "WARNING: Init bukan OpenRC. Beberapa fitur mungkin tidak bekerja."
fi

# --- Install git & stow ---
echo "[1/4] Installing git & stow..."
sudo pacman -Sy --noconfirm git stow

# --- Clone dotfiles ---
echo "[2/4] Cloning dotfiles..."
if [ -d "$DOTFILES_DIR/.git" ]; then
    echo "  dotfiles sudah ada, pull latest..."
    git -C "$DOTFILES_DIR" pull --rebase
else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# --- Run installer ---
echo "[3/4] Running install.sh..."
chmod +x "$DOTFILES_DIR/install.sh"
"$DOTFILES_DIR/install.sh"

# --- Post-install notes ---
echo ""
echo "[4/4] Post-install checklist:"
echo "  1. Review pkg/native.txt — hapus paket yang tidak perlu"
echo "  2. Review pkg/aur.txt — hapus paket yang tidak perlu"
echo "  3. Jalankan: bash generate-manifest.sh (untuk update manifest)"
echo "  4. Copy hardware configs: cp /etc/X11/xorg.conf.d/* pkg/hardware/"
echo "  5. Backup data lama: rsync -avP /mnt/old/home/ ~/  (via live USB)"
echo "  6. Reboot: sudo reboot"
echo ""
echo "Done!"
