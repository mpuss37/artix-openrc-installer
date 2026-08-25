#!/bin/bash
# Generate package manifest dari sistem Artix Linux yang berjalan
# Jalankan sekali di sistem yang sudah lengkap, hasilnya dipakai install.sh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$DOTFILES_DIR/pkg"

mkdir -p "$PKG_DIR"

echo "=== Generating package manifest ==="

# Native packages (official repos) — explicit + dependensi yang diperlukan
echo "[1/3] Native packages..."
pacman -Qqe | grep -v '^lib32-' | grep -v '^linux-firmware' | sort > "$PKG_DIR/native.txt"
echo "  $(wc -l < "$PKG_DIR/native.txt") packages → pkg/native.txt"

# AUR packages
echo "[2/3] AUR packages..."
if command -v yay &>/dev/null; then
    yay -Qqe | grep -v "^$(pacman -Qqe | tr '\n' '|' | sed 's/|$//')$" 2>/dev/null || true
    # Fallback: check packages not in official repos
    for pkg in $(yay -Qqe 2>/dev/null); do
        if ! pacman -Si "$pkg" &>/dev/null 2>&1; then
            echo "$pkg"
        fi
    done | sort -u > "$PKG_DIR/aur.txt"
elif command -v paru &>/dev/null; then
    paru -Qqe | while read -r pkg; do
        pacman -Si "$pkg" &>/dev/null 2>&1 || echo "$pkg"
    done | sort -u > "$PKG_DIR/aur.txt"
else
    echo "# Run this on a system with yay/paru installed" > "$PKG_DIR/aur.txt"
    echo "# Or manually list AUR packages here" >> "$PKG_DIR/aur.txt"
fi
echo "  $(wc -l < "$PKG_DIR/aur.txt") packages → pkg/aur.txt"

# OpenRC services
echo "[3/3] OpenRC services..."
SVC_FILE="$PKG_DIR/../system/openrc/services.txt"
: > "$SVC_FILE"

for level in sysinit boot default; do
    dir="/etc/runlevels/$level"
    if [ -d "$dir" ]; then
        for svc in "$dir"/*; do
            svc_name="$(basename "$svc")"
            # Skip broken symlinks
            if [ -L "$svc" ] && [ ! -e "$svc" ]; then
                echo "# SKIP (broken symlink): $level/$svc_name" >> "$SVC_FILE"
                continue
            fi
            echo "$level|$svc_name" >> "$SVC_FILE"
        done
    fi
done

echo "  $(grep -c '|' "$SVC_FILE") services → system/openrc/services.txt"

echo "=== Done! Review pkg/native.txt and pkg/aur.txt ==="
echo "Remove unwanted packages from native.txt before running install.sh"
