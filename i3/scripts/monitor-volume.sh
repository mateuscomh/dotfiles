#!/usr/bin/env bash

set -euo pipefail

# Descobre onde o som está saindo agora
CURRENT_SINK=$(pactl get-default-sink)
SINK_MONITOR="alsa_output.pci-0000_08_00.1.hdmi-stereo"

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/monitor-volume.last"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/monitor-volume.lock"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# ==========================================
# LÓGICA PARA O MONITOR (DDCUTIL)
# ==========================================
if [ "$CURRENT_SINK" = "$SINK_MONITOR" ]; then

    STEP=10
    MIN=0
    MAX=100
    VCP=62

    get_volume() {
        ddcutil getvcp "$VCP" --terse | awk '{print $4}'
    }

    set_volume() {
        local value=$1
        ddcutil --noverify setvcp "$VCP" "$value" >/dev/null
    }

    notify() {
        local volume=$1
        local icon

        if (( volume == 0 )); then icon="🔇"
        elif (( volume < 35 )); then icon="🔈"
        elif (( volume < 70 )); then icon="🔉"
        else icon="🔊"; fi

        dunstify -a "Monitor" -u low -h string:x-dunst-stack-tag:monitor-volume -h int:value:"$volume" "$icon Volume do Monitor" "${volume}%"
    }

    CURRENT=$(get_volume)

    case "${1:-}" in
        up)   NEW=$((CURRENT + STEP)) ;;
        down) NEW=$((CURRENT - STEP)) ;;
        mute)
            if (( CURRENT == 0 )); then
                if [[ -f "$STATE_FILE" ]]; then NEW=$(cat "$STATE_FILE"); else NEW=30; fi
            else
                echo "$CURRENT" > "$STATE_FILE"
                NEW=0
            fi
            ;;
        *) echo "Uso: $0 {up|down|mute}"; exit 1 ;;
    esac

    (( NEW > MAX )) && NEW=$MAX
    (( NEW < MIN )) && NEW=$MIN

    set_volume "$NEW"
    notify "$NEW"

# ==========================================
# LÓGICA PARA FONE / DAC (PACTL)
# ==========================================
else
    # 35% é muito agressivo para fones, defini o passo para 5%
    STEP_PA=5 

    case "${1:-}" in
        up)   pactl set-sink-volume @DEFAULT_SINK@ +${STEP_PA}% ;;
        down) pactl set-sink-volume @DEFAULT_SINK@ -${STEP_PA}% ;;
        mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
        *) echo "Uso: $0 {up|down|mute}"; exit 1 ;;
    esac

    # Pega o volume e o status de mudo atualizados do PulseAudio para notificar
    VOL_PA=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1)
    MUTE_STATE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

    if [ "$MUTE_STATE" = "yes" ] || [ "$VOL_PA" -eq 0 ]; then
        icon="🔇"
    elif [ "$VOL_PA" -lt 35 ]; then
        icon="🔈"
    elif [ "$VOL_PA" -lt 70 ]; then
        icon="🔉"
    else
        icon="🔊"
    fi

    # Notifica usando o mesmo padrão, mas especificando que é o fone
    dunstify -a "Fone" -u low -h string:x-dunst-stack-tag:monitor-volume -h int:value:"$VOL_PA" "$icon Volume do Fone" "${VOL_PA}%"
fi
