# Artix Linux OpenRC Installer

> **System**: Artix Linux (OpenRC) | Kernel 7.x | i3wm + XFCE4
> **Init**: OpenRC (systemd-free)
> **Hardware**: Intel i3-1005G1, NVMe SSD + 1TB HDD

Post-install automation untuk sistem Artix Linux OpenRC. Jalankan sekali setelah base install, semua paket + config + services terotomasi.

---

## Panduan Lengkap: Dari Nol Sampai Jalan

### Langkah 1 — Download ISO

Download Artix Linux OpenRC dari:
```
https://artixlinux.org/download.php
```
Pilih variant:
- `artix-openrc-base` — minimal, paling ringan (recommended)
- `artix-xfce-openrc` — sudah include XFCE4 desktop

Pilih desktop environment:
- `openrc` (base only, CLI)
- `openrc-xfce` (XFCE4)
- `openrc-i3` (i3wm)

### Langkah 2 — Buat Bootable USB

**Linux:**
```bash
# Cari device USB (jangan salah pilih!)
lsblk

# Flash ISO ke USB (ganti /dev/sdX dengan device USB kamu)
sudo dd if=artix-openrc-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

**Windows:**
1. Download Rufus: https://rufus.ie
2. Insert USB minimal 4GB
3. Buka Rufus → pilih ISO Artix → Start
4. Pilih "DD Image mode" kalau ditanya

**macOS:**
```bash
sudo dd if=artix-openrc-*.iso of=/dev/rdiskN bs=4m status=progress
# Ganti N dengan nomor disk USB (lihat di Disk Utility)
```

### Langkah 3 — Boot dari USB

1. Insert USB ke laptop baru
2. Restart → tekan F2/F12/DEL/ESC (tergantung merk laptop) masuk BIOS/UEFI
3. Disable Secure Boot (biasanya di tab Security)
4. Set boot priority: USB first
5. Save & restart

Kalau tidak masuk BIOS:
- **Lenovo**: F2 (setup) atau F12 (boot menu)
- **HP**: F10 (setup) atau F9 (boot menu)
- **ASUS**: F2 atau Del
- **Acer**: F2 atau Del

### Langkah 4 — Koneksi Internet

**WiFi:**
```bash
# Load wireless module
sudo modprobe iwlwifi    # Intel WiFi
sudo modprobe wlp2s0     # Atheros (ganti sesuai hardware)

# Scan & connect
sudo wifi-menu           # mudah (curses-based)
# Atau manual:
sudo ip link set wlan0 up
sudo iwctl station wlan0 scan
sudo iwctl station wlan0 connect "NamaWiFi"
sudo iwctl station wlan0 passwd "PasswordWiFi"

# Test koneksi
ping -c 3 archlinux.org
```

**Ethernet (kabel):**
```bash
sudo dhcpcd enp0s3    # ganti enp0s3 dengan nama interface
# Biasanya langsung jalan kalau pakai kabel
ping -c 3 archlinux.org
```

**Kalau tidak bisa connect:**
```bash
# Cek interface yang ada
ip link

# Wireless biasanya: wlan0, wlp2s0, wlp3s0
# Ethernet biasanya: enp0s3, enp3s0, eth0
```

### Langkah 5 — Partition Disk

**Opsi A: Manual (recommended untuk kontrol penuh)**

```bash
# Jalankan cfdisk (TUI-based, mudah dipakai)
sudo cfdisk /dev/nvme0n1
```

Buat partisi:
```
┌──────────────────────────────────────────────────────┐
│ Device          Size     Type        Mount            │
├──────────────────────────────────────────────────────┤
│ /dev/nvme0n1p1  512MB    EFI System   /boot/efi      │
│ /dev/nvme0n1p2  8GB      Linux swap   (swap)         │
│ /dev/nvme0n1p3  50GB+    Linux ext4   /              │
│ /dev/nvme0n1p4  Sisa     Linux ext4   /home          │
└──────────────────────────────────────────────────────┘
```

Langkah di cfdisk:
1. Pilih `gpt` (untuk UEFI) atau `dos` (untuk Legacy BIOS)
2. `[ New ]` → 512MB → Type: EFI System
3. `[ New ]` → 8GB → Type: Linux swap
4. `[ New ]` → 50GB → Type: Linux filesystem
5. `[ New ]` → Sisa semua → Type: Linux filesystem
6. `[ Write ]` → ketik `yes`
7. `[ Quit ]`

Format partisi:
```bash
# EFI
sudo mkfs.fat -F32 /dev/nvme0n1p1

# Swap
sudo mkswap /dev/nvme0n1p2
sudo swapon /dev/nvme0n1p2

# Root
sudo mkfs.ext4 /dev/nvme0n1p3

# Home
sudo mkfs.ext4 /dev/nvme0n1p4
```

**Opsi B: Pakai archinstall (semi-otomatis)**
```bash
# Di live ISO, jalankan:
archinstall
# Pilih: OpenRC, pilih partisi manual, ikuti wizard
```

### Langkah 6 — Mount & Install Base System

```bash
# Mount partisi
sudo mount /dev/nvme0n1p3 /mnt
sudo mkdir -p /mnt/boot/efi
sudo mount /dev/nvme0n1p1 /mnt/boot/efi
sudo mkdir -p /mnt/home
sudo mount /dev/nvme0n1p4 /mnt/home

# Install base system
sudo pacstrap /mnt base base-devel linux linux-headers linux-firmware openssh

# Generate fstab
sudo genfstab -U /mnt >> /mnt/etc/fstab

# Chroot ke sistem baru
sudo arch-chroot /mnt
```

### Langkah 7 — Setup Sistem di Chroot

```bash
# Timezone
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "artix" > /etc/hostname

# Root password
passwd

# Buat user (INI YANG DIMAKSUD "USER SUDAH DIBUAT")
useradd -m -G wheel,audio,video,storage -s /bin/bash mpuss
passwd mpuss

# Install GRUB
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable network
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager    # atau openrc service nanti

# Install OpenRC (kalau pakai artix-openrc-base, sudah termasuk)
# Pastikan init system benar:
cat /proc/1/comm    # harus: openrc (atau s6, runit, etc.)

# Exit chroot
exit
```

### Langkah 8 — Reboot & Login

```bash
sudo umount -R /mnt
sudo reboot
```

Login dengan user `mpuss` (atau user yang dibuat tadi).

### Langkah 9 — Jalankan Installer

```bash
# Clone dotfiles
git clone https://github.com/mpuss37/artix-openrc-installer.git ~/dotfiles
cd ~/dotfiles

# Jalankan
./bootstrap.sh
```

Installer akan otomatis:
1. Install git & stow
2. Install 300+ native packages
3. Install yay (AUR helper)
4. Install 43 AUR packages
5. Stow dotfiles (bashrc, i3, kitty, picom, etc.)
6. Copy system configs (/etc/X11, nftables, fail2ban, etc.)
7. Enable OpenRC services
8. Reload configs

### Langkah 10 — Setup Disk Data (opsional)

Kalau ada disk 1TB:
```bash
# Cari device
lsblk

# Format
sudo mkfs.ext4 /dev/sda3

# Mount
sudo mkdir -p /home/mpuss/disk/data1tb
sudo mount /dev/sda3 /home/mpuss/disk/data1tb

# Tambah ke /etc/fstab (otomatis mount saat boot)
echo "UUID=$(blkid -s UUID -o value /dev/sda3) /home/mpuss/disk/data1tb ext4 rw,noatime 0 2" | sudo tee -a /etc/fstab
```

### Langkah 11 — Backup Data Lama

```bash
# Dari laptop baru, tarik data dari laptop lama via SSH
rsync -avP --progress mpuss@192.168.x.x:/home/mpuss/ /home/mpuss/

# Atau kalau pakai disk eksternal
sudo mount /dev/sdb1 /mnt/external
rsync -avP /mnt/external/home/ /home/mpuss/
```

---

## Prerequisites Summary

| # | Syarat | Status |
|---|--------|--------|
| 1 | ISO Artix OpenRC terdownload | |
| 2 | Bootable USB sudah dibuat (dd/Rufus) | |
| 3 | Boot dari USB (disable Secure Boot) | |
| 4 | Koneksi internet aktif (WiFi/Ethernet) | |
| 5 | Partisi terpasang (EFI + swap + / + /home) | |
| 6 | Base system terinstall (base, linux, grub) | |
| 7 | User sudah dibuat (useradd -m -G wheel) | |
| 8 | GRUB terinstall & configured | |
| 9 | Reboot ke sistem baru | |
| 10 | Jalankan `bootstrap.sh` | |

---

## Quick Start (setelah base install selesai)

```bash
git clone https://github.com/mpuss37/artix-openrc-installer.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

## Install Options

```bash
./install.sh              # Full install
./install.sh --dry-run    # Cek dulu tanpa ubah sistem
./install.sh --hardware   # Include intel.conf, touchpad, battery
./install.sh --no-packages  # Skip package install
./install.sh --no-services  # Skip service enablement
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
├── install.sh              # Main installer
├── bootstrap.sh            # Entry point laptop baru
├── generate-manifest.sh    # Regenerate package list
├── pkg/
│   ├── native.txt          # 300 paket official repos
│   ├── aur.txt             # 43 paket AUR
│   └── hardware/           # Config per-laptop
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

```bash
bash generate-manifest.sh
# Edit pkg/native.txt & pkg/aur.txt
# Commit & push
```
