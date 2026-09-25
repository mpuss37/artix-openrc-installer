#!/bin/bash

# Deteksi sink Bluetooth/TWS aktif secara DINAMIS (tidak hardcode MAC).
# Nama device bisa berubah (TALIX TA12 / talix12), jadi jangan bergantung MAC.

# Prioritas deteksi sink Bluetooth:
#   1. bluez sink yang RUNNING (sedang main audio)
#   2. bluez sink apa saja (IDLE/SUSPENDED tapi terhubung)
SINK=$(pactl list sinks | grep -B 1 "State: RUNNING" | grep -oE "bluez_sink\.[0-9A-Fa-f_]+(\.[a-z0-9_]+)?_sink" | head -n 1)
[ -z "$SINK" ] && SINK=$(pactl list short sinks | awk '$2 ~ /bluez_sink/ {print $2; exit}')

if [ -n "$SINK" ]; then
    echo "Sink aktif (Bluetooth/TWS): $SINK"

    # Pastikan sink default mengarah ke TWS ini.
    if [[ "$(pactl get-default-sink)" != "$SINK" ]]; then
        pactl set-default-sink "$SINK"
        echo "Default sink dipindah ke: $SINK"
    fi

    # Mendapatkan volume channel kiri dan kanan saat ini
    LEFT_VOLUME=$(pactl list sinks | grep -A 20 "Name: $SINK" | grep "Volume:" | head -1 | awk '{print $5}' | tr -d '%')
    RIGHT_VOLUME=$(pactl list sinks | grep -A 20 "Name: $SINK" | grep "Volume:" | head -1 | awk '{print $12}' | tr -d '%')

    # Handle sink mono (HFP) — kolom kanan tidak ada
    [ -z "$RIGHT_VOLUME" ] && RIGHT_VOLUME=$LEFT_VOLUME

    echo "Volume kiri: $LEFT_VOLUME%"
    echo "Volume kanan: $RIGHT_VOLUME%"

    # Menambah 10% ke channel kiri dan kanan (maks 400%)
    NEW_LEFT_VOLUME=$((LEFT_VOLUME + 10))
    NEW_RIGHT_VOLUME=$((RIGHT_VOLUME + 10))

    if [ $NEW_LEFT_VOLUME -gt 400 ]; then
        NEW_LEFT_VOLUME=400
    fi

    if [ $NEW_RIGHT_VOLUME -gt 400 ]; then
        NEW_RIGHT_VOLUME=400
    fi

    # Atur volume channel kiri dan kanan
    pactl set-sink-volume "$SINK" ${NEW_LEFT_VOLUME}% ${NEW_RIGHT_VOLUME}%
    echo "Volume diatur ke kiri: ${NEW_LEFT_VOLUME}%, kanan: ${NEW_RIGHT_VOLUME}%"
else
    echo "Tidak ada sink Bluetooth/TWS aktif. Menggunakan logika default (speaker laptop)."

    # Mendapatkan sink default
    SINK=$(pactl info | grep "Default Sink" | cut -d ' ' -f3)

    # Mendapatkan volume channel kiri saat ini
    LEFT_VOLUME=$(pactl list sinks | grep -A 20 "Name: $SINK" | grep "Volume:" | head -1 | awk '{print $5}' | tr -d '%')
    echo "Sink default: $SINK"
    echo "Volume kiri: $LEFT_VOLUME%"

    # Menambah 10% ke channel kiri (maks 400%)
    NEW_LEFT_VOLUME=$((LEFT_VOLUME + 10))
    if [ $NEW_LEFT_VOLUME -gt 400 ]; then
        NEW_LEFT_VOLUME=400
    fi

    # Atur volume channel kiri (kiri: NEW_LEFT_VOLUME%, kanan: 0%)
    pactl set-sink-volume "$SINK" ${NEW_LEFT_VOLUME}% 0%
    echo "Volume diatur ke kiri: ${NEW_LEFT_VOLUME}%, kanan: 0%"
fi
