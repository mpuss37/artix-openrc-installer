#!/bin/bash
# Bootstrap untuk laptop baru — jalankan SEKALI setelah install Artix OpenRC
# Usage: curl -fsSL <raw-github-url>/bootstrap.sh | bash
#   atau: scp bootstrap.sh user@new-laptop:~/ && bash bootstrap.sh
set -euo pipefail

DOTFILES_REPO="https://github.com/mpuss37/artix-openrc-installer.git"
DOTFILES_DIR="$HOME/dotfiles"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Artix Linux Bootstrap — Post-Install Automation        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# =========================================================
# PREREQUISITES — wajib terpenuhi sebelum jalankan script ini
# =========================================================
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  PREREQUISITES (cek sebelum jalankan!)                   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  [1] Base Artix Linux OpenRC sudah terinstall via ISO"
echo "      - Pilih: artix-openrc (base) atau artix-xfce-openrc"
echo "      - Download: https://artixlinux.org/download.php"
echo ""
echo "  [2] Partisi sudah terpasang:"
echo "      ┌──────────────────────────────────┐"
echo "      │ /dev/nvme0n1p1  boot/efi  512MB  │ vfat   → /boot/efi"
echo "      │ /dev/nvme0n1p2  swap      4-8GB  │ swap   (atau swapfile)"
echo "      │ /dev/nvme0n1p3  /         50GB+  │ ext4"
echo "      │ /dev/nvme0n1p4  /home     sisa   │ ext4"
echo "      └──────────────────────────────────┘"
echo "      Untuk disk data (1TB), partisi manual setelah install:"
echo "        sudo mkfs.ext4 /dev/sdXN"
echo "        sudo mkdir -p /home/mpuss/disk/data1tb"
echo "        Tambah ke /etc/fstab:"
echo "        UUID=<uuid> /home/mpuss/disk/data1tb ext4 rw,noatime 0 2"
echo ""
echo "  [3] User 'mpuss' (atau user kamu) sudah terbuat saat install"
echo ""
echo "  [4] Koneksi internet aktif"
echo ""
echo "  [5] (Opsional) SSH key sudah terdaftar di GitHub:"
echo "        ssh-keygen -t ed25519"
echo "        cat ~/.ssh/id_ed25519.pub  # paste ke GitHub Settings → SSH keys"
echo ""

# --- Pre-check ---
if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: Jangan jalankan sebagai root."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    echo "ERROR: Bukan sistem Arch/Artix."
    exit 1
fi

if ! grep -q "openrc" /proc/1/comm 2>/dev/null; then
    echo "WARNING: Init bukan OpenRC. Beberapa fitur mungkin tidak bekerja."
fi

# Cek partisi minimal
echo "=== Checking disk layout ==="
ROOT_OK=0
HOME_OK=0
EFI_OK=0

if mount | grep -q " on / "; then
    ROOT_OK=1
    echo "  ✓ Root partition mounted"
else
    echo "  ✗ Root partition tidak terdeteksi"
fi

if mount | grep -q " on /home "; then
    HOME_OK=1
    echo "  ✓ /home partition mounted"
else
    echo "  ✗ /home partition tidak terdeteksi (bisa pakai /home dir saja)"
fi

if mount | grep -q " on /boot/efi "; then
    EFI_OK=1
    echo "  ✓ EFI partition mounted"
else
    echo "  ⚠ EFI partition tidak terdeteksi (UEFI mode?)"
fi

echo ""

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
