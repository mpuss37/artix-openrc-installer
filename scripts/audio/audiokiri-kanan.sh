#!/bin/bash

# Ambil sink default
SINK=$(pactl info | awk -F': ' '/Default Sink/ {print $2}')

# Jika ada TWS/Bluetooth yang connect tapi default sink masih speaker laptop,
# pindahkan default sink ke TWS dulu (biar volume mengatur TWS).
BT_SINK=$(pactl list short sinks | awk '$2 ~ /bluez_sink/ {print $2}' | head -n 1)
if [ -n "$BT_SINK" ] && [[ "$SINK" != *bluez* ]]; then
    SINK="$BT_SINK"
    pactl set-default-sink "$SINK"
    echo "→ TWS terdeteksi, default sink dipindah ke: $SINK"
fi

echo "Sink: $SINK"

# Ambil volume kiri & kanan (handle stereo DAN mono)
read LEFT_VOLUME RIGHT_VOLUME <<< $(
    pactl list sinks |
    awk -v sink="$SINK" '
        $0 ~ "Name: "sink {found=1}
        found && /Volume:/ {
            if ($2 == "mono:") {
                gsub(/%/, "", $5)
                print $5, $5
                exit
            }
            gsub(/%/, "", $5)
            gsub(/%/, "", $12)
            print $5, $12
            exit
        }
    '
)

echo "Volume sekarang → kiri: ${LEFT_VOLUME}% | kanan: ${RIGHT_VOLUME}%"

STEP=6
# ponytail: laptop bisa 150%, Bluetooth mentok 100%
if [[ "$SINK" == *bluez* ]]; then
    MAX=100
else
    MAX=150
fi

NEW_LEFT=$((LEFT_VOLUME + STEP))
NEW_RIGHT=$((RIGHT_VOLUME + STEP))

[ $NEW_LEFT -gt $MAX ] && NEW_LEFT=$MAX
[ $NEW_RIGHT -gt $MAX ] && NEW_RIGHT=$MAX

if [[ "$SINK" == *a2dp* ]]; then
    echo "🎧 Stereo (A2DP)"
    pactl set-sink-volume "$SINK" ${NEW_LEFT}% ${NEW_RIGHT}%
elif [[ "$SINK" == *bluez* ]]; then
    echo "🎧 Bluetooth mono (HFP)"
    pactl set-sink-volume "$SINK" ${NEW_LEFT}%
else
    echo "💻 Speaker laptop → mono kiri"
    pactl set-sink-volume "$SINK" ${NEW_LEFT}% 0%
fi

echo "Volume → kiri: ${NEW_LEFT}% | kanan: ${NEW_RIGHT}%"
