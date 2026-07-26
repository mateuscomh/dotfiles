#!/usr/bin/env bash

set -euo pipefail

STEP=35
MIN=0
MAX=100

VCP=62

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/monitor-volume.last"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/monitor-volume.lock"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

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

    if (( volume == 0 )); then
        icon="🔇"
    elif (( volume < 35 )); then
        icon="🔈"
    elif (( volume < 70 )); then
        icon="🔉"
    else
        icon="🔊"
    fi

    dunstify \
        -a "Monitor" \
        -u low \
        -h string:x-dunst-stack-tag:monitor-volume \
        -h int:value:"$volume" \
        "$icon Volume do monitor" \
        "${volume}%"
}

CURRENT=$(get_volume)

case "${1:-}" in
    up)
        NEW=$((CURRENT + STEP))
        ;;

    down)
        NEW=$((CURRENT - STEP))
        ;;

    mute)
        if (( CURRENT == 0 )); then
            if [[ -f "$STATE_FILE" ]]; then
                NEW=$(cat "$STATE_FILE")
            else
                NEW=30
            fi
        else
            echo "$CURRENT" > "$STATE_FILE"
            NEW=0
        fi
        ;;

    *)
        echo "Uso: $0 {up|down|mute}"
        exit 1
        ;;
esac

(( NEW > MAX )) && NEW=$MAX
(( NEW < MIN )) && NEW=$MIN

set_volume "$NEW"
notify "$NEW"
