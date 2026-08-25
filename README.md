# Artix Linux OpenRC Installer

> **System**: Artix Linux (OpenRC) | Kernel 7.x | i3wm + XFCE4
> **Init**: OpenRC (systemd-free)
> **Hardware**: Intel i3-1005G1, NVMe SSD + 1TB HDD

Post-install automation untuk sistem Artix Linux OpenRC. Jalankan sekali setelah base install, semua paket + config + services terotomasi.

## Prerequisites

Sebelum jalankan installer, pastikan:

1. **Base Artix Linux OpenRC sudah terinstall** via ISO
   - Download: https://artixlinux.org/download.php
   - Pilih variant: `artix-openrc` (minimal) atau `artix-xfce-openrc`

2. **Partisi sudah terpasang:**
   ```
   /dev/nvme0n1p1  boot/efi   512MB   vfat    → /boot/efi
   /dev/nvme0n1p2  swap       4-8GB   swap/swapfile
   /dev/nvme0n1p3  /          50GB+   ext4
   /dev/nvme0n1p4  /home      sisa    ext4
   ```

3. **Disk data (opsional):**
   ```bash
   sudo mkfs.ext4 /dev/sdXN
   sudo mkdir -p /home/mpuss/disk/data1tb
   # Tambah ke /etc/fstab:
   UUID=<uuid> /home/mpuss/disk/data1tb ext4 rw,noatime 0 2
   ```

4. **User sudah terbuat** saat install (misal: `mpuss`)

5. **Koneksi internet aktif**

6. **(Opsional) SSH key untuk GitHub:**
   ```bash
   ssh-keygen -t ed25519
   cat ~/.ssh/id_ed25519.pub  # paste ke GitHub Settings → SSH keys
   ```

## Quick Start

```bash
# Clone & jalankan
git clone https://github.com/mpuss37/artix-openrc-installer.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh          # otomatis (install deps + clone + jalankan installer)

# Atau manual
./install.sh            # full install
./install.sh --dry-run  # cek dulu tanpa ubah sistem
./install.sh --hardware # include intel.conf, touchpad, battery-threshold
```

## What It Does

| Step | Action |
|------|--------|
| 1 | Sync pacman keyring |
| 2 | Install 300+ native packages (official repos) |
| 3 | Install yay (AUR helper) |
| 4 | Install 43 AUR packages |
| 5 | Stow dotfiles (bashrc, i3, kitty, picom, etc.) |
| 6 | Copy system configs (/etc/X11, modprobe, udev, sysctl, nftables, etc.) |
| 7 | Enable OpenRC services (NetworkManager, docker, fail2ban, etc.) |
| 8 | Reload configs (sysctl, nftables, fail2ban) |

## Structure

```
dotfiles/
├── install.sh              # Main installer (post-install automation)
├── bootstrap.sh            # Entry point untuk laptop baru
├── generate-manifest.sh    # Regenerate package list dari sistem jalan
├── pkg/
│   ├── native.txt          # 300 paket official repos
│   ├── aur.txt             # 43 paket AUR
│   └── hardware/           # Config per-laptop (intel, touchpad, etc.)
├── bashrc/                 # Shell config
├── i3/                     # i3 window manager
├── kitty/                  # Kitty terminal
├── picom/                  # Compositor
├── i3status/               # Status bar
├── scripts/                # Automation scripts
└── system/                 # System configs (need root)
    ├── openrc/
    │   └── services.txt    # Service enablement map
    ├── xorg/               # X11 configs
    ├── modprobe.d/         # Kernel module options
    ├── sysctl.d/           # Kernel parameters
    ├── nftables/           # Firewall rules
    ├── audit/              # Audit rules
    ├── polkit/             # Polkit rules
    └── fail2ban/           # Fail2ban config
```

## Regenerate Manifest

Kalau paket berubah di sistem yang berjalan:

```bash
bash generate-manifest.sh
# Edit pkg/native.txt & pkg/aur.txt sesuai kebutuhan
# Commit & push
```

## Backup Data Lama

```bash
# Via SSH dari laptop baru
rsync -avP --progress old-laptop:/home/mpuss/ /home/mpuss/

# Atau via disk eksternal
rsync -avP /mnt/old/home/ /home/mpuss/
```
