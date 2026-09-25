#echo "cek 'task' her"
#catatan
#sudo dpkg --configure -a (nek error dev/pts virtualbox)
#VBoxManage startvm "jeneng-virtual-e" --type headless
#folder /tmp iku penting gae simpenan package seng bedo versi
#gae ngae hostpot
#nmcli device wifi hotspot ssid "SSID" password "PASSWORD"

alias c='clear';
alias x='exit';
alias re='reset';
alias f='feh';
alias nf='neofetch';
alias C='clear';
alias ms='mocp';
alias ms-c='echo "" > /home/mpuss/.moc/pid';
alias sam='sudo /opt/lampp/lampp startapache && sudo /opt/lampp/lampp startmysql';
alias sam-status='sudo /opt/lampp/lampp status';
alias sam-stop='sudo /opt/lampp/lampp stop';
alias post-start='sudo rc-service postgresql start';
alias post-status='sudo rc-service postgresql status';
alias post-stop='sudo rc-service postgresql stop';
alias ks='ls -d */';
alias fd='sudo fdisk -l';
#alias tb='/home/mpuss/kodingan/skrip/tbw.sh';
alias md='echo "" > /home/mpuss/.moc/pid';
alias er='ranger';
#alias as='calcurse';
IP=$(ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')
alias server='python3 -m http.server 9000 --bind $IP';
alias rekam='simplescreenrecorder --start-hidden'
alias upower-bt='upower  -i /org/freedesktop/UPower/devices/headset_dev_41_42_FF_2B_59_10'
alias upower-btt='upower  -i /org/freedesktop/UPower/devices/headset_dev_41_42_A0_34_C5_0C'
alias rm='rm -I --preserve-root'
alias windos='wine explorer /desktop=MyWineDesktop,1366x768'
alias btl='blueman-manager'
alias bt='sudo rc-service /etc/init.d/bluetoothd start && bluetoothctl'
alias bt-stop='bluetoothctl disconnect && sudo rc-service bluetoothd stop'
alias ta='task'
alias nmcli-pass='nmcli dev wifi show-password'
#alias pactl-hdmi='pactl set-card-profile 0 output:hdmi-stereo'
jam1=$(date +"%I:%M %p")

#custom-panjang
alias lsblk-list='lsblk -d -o NAME,MODEL,SIZE,TYPE,ROTA'
alias vbox-start='VBoxManage startvm $1 --type headless'
alias vbox-list='VBoxManage list vms'
alias vbox-list-run='VBoxManage list runningvms'
alias yt-dlp-ms='yt-dlp --extract-audio --audio-format mp3 --audio-quality 0 --no-playlist $1';
#alias rate-mirrors-n='rate-mirrors --allow-root --protocol https artix | grep -v '^#' | sudo tee /etc/pacman.d/mirrorlist'
#alias rate-mirrors-n='sudo rate-mirrors --allow-root --protocol https --entry-country Indonesia --country-neighbors-per-country 5 --concurrency 10 --max-per-mirror 5 artix | sudo tee /etc/pacman.d/mirrorlist'
#rate-mirrors: ambil mirror tercepat + terstabil, simpan atomik, backup otomatis
rate-mirrors-n() {
    local conf=/etc/pacman.d/mirrorlist
    # backup sekali (jangan timpa backup lama)
    sudo cp -n "$conf" "$conf.bak" 2>/dev/null
    sudo rate-mirrors --allow-root \
        --save "$conf" \
        --protocol https \
        --entry-country Indonesia \
        --country-neighbors-per-country 5 \
        --country-test-mirrors-per-country 5 \
        --concurrency 20 \
        --min-per-mirror 500 \
        --max-per-mirror 1500 \
        --eps 0.05 \
        --eps-checks 60 \
        --top-mirrors-number-to-retest 10 \
        --max-mirrors-to-output 5 \
        artix
    if [ $? -eq 0 ]; then
        echo ">> Mirror tercepat+terstabil tersimpan. Backup: $conf.bak"
        sudo pacman -Syy
    else
        echo ">> GAGAL - mirrorlist tidak diubah (masih pakai yang lama)"
    fi
}
alias mysql-sam='/opt/lampp/bin/./mysql -u root'
alias xrandr-umum='xrandr --output HDMI1 --auto --right-of eDP1'
alias pactl-list='pactl list short sinks'
alias pactl-def='pactl set-default-sink $1';
alias modprobe-usb-idup='sudo modprobe usb-storage && sudo modprobe uas'
alias modprobe-usb-mati='sudo rmmod uas && sudo rmmod usb_storage'

#bagian export
#LS_COLORS=$LS_COLORS:'di=0;31:ex=0;33:' ; export LS_COLORS
LS_COLORS=$LS_COLORS:'di=0:ln=36:so=34:pi=34:ex=36:bd=34;46:cd=30;46:su=30;46:sg=30;46:tw=0;44:ow=0' ; export LS_COLORS
#export PS1="(\$(date +'%I:%M %p'))\w \[$(tput sgr0)\]"

export PS1="\[\e[37;44m\]\[\e[m\](\$(date +'%I:%M %p'))\w \[$(tput sgr0)\]"
#export PS1="\[\e[37;44m\]\[\e[m\]\w \[$(tput sgr0)\]"
#export PS1="\[\e[37;44m\]JANGAN LUPA DICEK RENCANA,TARGET,KERJOAN, LS DISEK !!! \[\e[m\]\n(\$(date +'%I:%M %p'))\w \[$(tput sgr0)\]"
#export PS1="[\e[\]JANGAN LUPA DICEK RENCANA,TARGET,KERJOAN\n($jam1)\w \[$(tput sgr0)\]"
#digae laravel ben isok global
#export PATH=$PATH:$HOME/.config/composer/vendor/bin
#digae golang ben isok global
export PATH=$PATH:/usr/local/go/bin

#export untuk androidstudio dan kawan kawan
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

#export untuk mimo agentic ai
#export MIMO_API_KEY="your-api-key-here"
#export key : fe_oa_402b352fbf1aa90414b5e5619698c2ee32675eed7883b87d

#custom
#history > /home/mpuss/disk/data1tb/doc/notes/bash_history 

ls-t() { 
  ls -t | head -"$1"
}

#digae savestate serper jalan nang virtualbox
vbox-save() {
    VBoxManage controlvm "$1" savestate
}

pacman-s() {
    pacman -Ss "$1" | grep -E "^[a-zA-Z0-9]+/[a-zA-Z0-9]" | head -10
}

copas() {
    if [ -z "$1" ]; then
        echo "Usage: copas <file>"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "File tidak ditemukan: $1"
        return 1
    fi
    xclip -selection clipboard < "$1" && echo "Tersalin: $1"
}

alias rasan='java -jar /home/mpuss/Downloads/file-github/rasan/build/libs/kuncen-1.0-SNAPSHOT.jar' 

# Created by `pipx` on 2026-07-22 12:25:23
export PATH="$PATH:/home/mpuss/.local/bin"

#bash-completion openrc (rc-service, rc-status, rc-update)
for f in /usr/share/bash-completion/completions/rc-*; do source "$f"; done

# opencode
export PATH=/home/mpuss/.opencode/bin:$PATH
