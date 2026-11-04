#!/usr/bin/env bash

###############################################################################
# i3-smart-lock.sh
#
# Uso:
#   ./i3-smart-lock.sh          -> espera 15s e inicia o bloqueio
#   ./i3-smart-lock.sh 30       -> espera 30s
#   ./i3-smart-lock.sh now      -> bloqueia imediatamente
#
# Fluxo normal:
#   1. Captura a tela
#   2. Inicia o blur em background
#   3. Monitora teclado/mouse
#   4. Exibe contagem regressiva no Dunst
#   5. Faz fade-out do brilho
#   6. Restaura o brilho original
#   7. Aguarda o blur
#   8. Inicia o i3lock
#
# Dependências:
#   bash
#   xrandr
#   xdotool
#   xinput
#   maim
#   ImageMagick (convert)
#   dunstify
#   i3lock
#   awk
#   gammastep
###############################################################################

set -u
set -o pipefail

###############################################################################
# CONFIGURAÇÕES
###############################################################################

DEFAULT_WAIT=15
FADE_SECONDS=15

MIN_BRIGHTNESS=20
BLUR_LEVEL="0x5"

TEMP_BG="/tmp/i3lock_screen.png"
DUNST_ID=500

###############################################################################
# ARGUMENTOS
###############################################################################

MODE="normal"
WAIT_SECONDS="$DEFAULT_WAIT"

if [[ "${1:-}" == "now" ]]; then
    MODE="now"
elif [[ -n "${1:-}" ]]; then
    if [[ "${1}" =~ ^[0-9]+$ ]]; then
        WAIT_SECONDS="$1"
    else
        echo "Uso: $0 [segundos|now]"
        exit 1
    fi
fi

###############################################################################
# PREVINE EXECUÇÕES DUPLICADAS
###############################################################################

if pgrep -x "i3lock" >/dev/null 2>&1; then
    exit 0
fi

###############################################################################
# VARIÁVEIS GLOBAIS
###############################################################################

BRIGHT_CHANGED=0

blur_pid=""
key_pid=""

initial_mouse=""

declare -a OUTPUTS=()
declare -a RESTORE_ARGS=()

###############################################################################
# LIMPEZA / RESTAURAÇÃO
###############################################################################

cleanup() {

    # Restaura brilho caso tenha sido alterado
    if [[ "$BRIGHT_CHANGED" -eq 1 ]] &&
       [[ "${#RESTORE_ARGS[@]}" -gt 0 ]]; then

        xrandr "${RESTORE_ARGS[@]}" >/dev/null 2>&1 || true

        BRIGHT_CHANGED=0
    fi

    # Encerra processo de blur
    if [[ -n "$blur_pid" ]] &&
       kill -0 "$blur_pid" 2>/dev/null; then

        kill "$blur_pid" 2>/dev/null || true
        wait "$blur_pid" 2>/dev/null || true
    fi

    # Encerra monitor de teclado
    if [[ -n "$key_pid" ]] &&
       kill -0 "$key_pid" 2>/dev/null; then

        pkill -P "$key_pid" 2>/dev/null || true
        kill "$key_pid" 2>/dev/null || true
        wait "$key_pid" 2>/dev/null || true
    fi

    # Remove imagem temporária
    rm -f "$TEMP_BG"

    # Remove notificação
    dunstify -C "$DUNST_ID" >/dev/null 2>&1 || true
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

###############################################################################
# DESCOBRE MONITORES
###############################################################################

get_outputs() {

    mapfile -t OUTPUTS < <(
        xrandr --query |
        awk '/ connected / && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {
            print $1
        }'
    )

    if [[ "${#OUTPUTS[@]}" -eq 0 ]]; then
        echo "Nenhum monitor conectado foi encontrado." >&2
        exit 1
    fi
}

###############################################################################
# CAPTURA BRILHO ORIGINAL
###############################################################################

get_brightness() {

    local raw_bright

    raw_bright=$(
        xrandr --verbose 2>/dev/null |
        awk '/Brightness:/ {
            print $2
            exit
        }'
    )

    raw_bright="${raw_bright:-1.0}"

    # Validação simples
    if ! awk -v b="$raw_bright" 'BEGIN {
        exit !(b >= 0 && b <= 1.0)
    }'; then

        raw_bright="1.0"
    fi

    ORIGINAL_BRIGHTNESS="$raw_bright"

    START_BRIGHT=$(
        awk -v b="$ORIGINAL_BRIGHTNESS" \
        'BEGIN {
            printf "%d", b * 100 + 0.5
        }'
    )

    # Monta argumentos para restauração
    RESTORE_ARGS=()

    for out in "${OUTPUTS[@]}"; do
        RESTORE_ARGS+=(
            --output "$out"
            --brightness "$ORIGINAL_BRIGHTNESS"
        )
    done
}

###############################################################################
# APLICA BRILHO
###############################################################################

set_brightness() {

    local brightness="$1"

    local args=()

    for out in "${OUTPUTS[@]}"; do
        args+=(
            --output "$out"
            --brightness "$brightness"
        )
    done

    xrandr "${args[@]}" >/dev/null 2>&1 || true
}

###############################################################################
# CAPTURA E BLUR
###############################################################################

capture_screen() {

    if ! maim "$TEMP_BG"; then
        echo "Erro ao capturar a tela com maim." >&2
        exit 1
    fi
}

blur_screen() {

    OMP_NUM_THREADS=1 \
    nice -n 19 \
    convert \
        -limit thread 1 \
        "$TEMP_BG" \
        -scale 10% \
        -filter Gaussian \
        -blur "$BLUR_LEVEL" \
        -scale 1000% \
        "$TEMP_BG"
}

start_blur() {

    (
        # Pequeno atraso para permitir que maim finalize completamente
        sleep 0.3

        # Não tenta processar uma imagem que já foi removida
        [[ -f "$TEMP_BG" ]] || exit 0

        blur_screen

    ) &

    blur_pid=$!
}

###############################################################################
# MONITOR DE TECLADO
###############################################################################

start_keyboard_monitor() {

    (
        stdbuf -oL xinput test-xi2 --root 2>/dev/null |
        grep --line-buffered -q "RawKeyPress"
    ) &

    key_pid=$!
}

###############################################################################
# VERIFICAÇÃO DE INTERRUPÇÃO
###############################################################################

check_interrupt() {

    local current_mouse

    current_mouse=$(
        xdotool getmouselocation --shell 2>/dev/null ||
        echo "$initial_mouse"
    )

    # Mouse mudou
    if [[ "$current_mouse" != "$initial_mouse" ]]; then

        dunstify \
            -r "$DUNST_ID" \
            --urgency=low \
            "Bloqueio cancelado" \
            "Movimento do mouse detectado."

        exit 0
    fi

    # Teclado detectado
    if [[ -n "$key_pid" ]] &&
       ! kill -0 "$key_pid" 2>/dev/null; then

        dunstify \
            -r "$DUNST_ID" \
            --urgency=low \
            "Bloqueio cancelado" \
            "Teclado detectado."

        exit 0
    fi
}

###############################################################################
# NOTIFICAÇÃO
###############################################################################

notify_progress() {

    local progress="$1"

    dunstify \
        --urgency=low \
        -h "int:value:$progress" \
        -h "string:hlcolor:#8844ff" \
        -r "$DUNST_ID" \
        "Bloqueando em breve..." \
        "$(date '+%T')" \
        >/dev/null 2>&1 || true
##        --icon=system-lock-screen \
}

###############################################################################
# CONTAGEM REGRESSIVA
###############################################################################

countdown() {

    # Captura posição inicial do mouse
    initial_mouse=$(
        xdotool getmouselocation --shell 2>/dev/null || true
    )

    start_keyboard_monitor

    if (( WAIT_SECONDS <= 0 )); then
        return
    fi

    local steps=$((WAIT_SECONDS * 4))
    local progress

    for ((i = 0; i <= steps; i++)); do

        check_interrupt

        if ((i % 4 == 0)); then

            progress=$((i * 100 / steps))

            notify_progress "$progress"
        fi

        sleep 0.25
    done
}

###############################################################################
# FADE OUT
###############################################################################
fade_out() {
    if (( FADE_SECONDS <= 0 )); then
        return
    fi

    BRIGHT_CHANGED=1

    sleep 0.5

    local steps=30
    
    # Calcula delay e todos os valores de brilho de uma vez só
    local delay
    delay=$(awk -v s="$FADE_SECONDS" -v st="$steps" 'BEGIN { printf "%.3f", s / st }')

    mapfile -t brightness_values < <(awk -v st="$steps" 'BEGIN {
        for(i=1; i<=st; i++) {
            printf "%.3f\n", 1 - (0.9 * i / st)
        }
    }')

    local i=0
    for b in "${brightness_values[@]}"; do
        ((i++))
        check_interrupt

        # Calcula a porcentagem e os segundos restantes
        local progress=$(( i * 100 / steps ))
        local remaining=$(( FADE_SECONDS - (i * FADE_SECONDS / steps) ))

        # Atualiza a notificação em tempo real
        dunstify \
            --urgency=low \
            -h "int:value:$progress" \
            -h "string:hlcolor:#8844ff" \
            -t 2000 \
            -r "$DUNST_ID" \
            "Escurecendo a tela..." \
            "Bloqueio total em ${remaining}s" \
            >/dev/null 2>&1 || true
#            --icon=system-lock-screen \

        gammastep -P -m randr -O 6500 -b "$b" >/dev/null 2>&1 || true
        
        sleep "$delay"
    done
}

###############################################################################
# RESTAURA BRILHO
###############################################################################

restore_brightness() {

    if [[ "$BRIGHT_CHANGED" -ne 1 ]]; then
        return
    fi

    gammastep -x >/dev/null 2>&1 || true

    BRIGHT_CHANGED=0
}

###############################################################################
# EXECUTA I3LOCK
###############################################################################

execute_lock() {

    i3lock \
        -i "$TEMP_BG" \
        --clock \
        --indicator \
        --line-uses-ring \
        --time-color='#A659DE' \
        --date-color='#B077D9' \
        --ring-color='#00000000' \
        --keyhl-color='#F299E1' \
        --verif-text="and.." \
        --wrong-text="" \
        --inside-color='00000000'
}

###############################################################################
# BLOQUEIO IMEDIATO
###############################################################################

lock_now() {

    # Captura
    capture_screen

    # Blur síncrono:
    # garante que a imagem esteja pronta antes do i3lock.
    blur_screen

    # Bloqueia imediatamente
    execute_lock
}

###############################################################################
# BLOQUEIO NORMAL
###############################################################################

lock_normal() {

    # 1. Captura
    capture_screen

    # 2. Inicia blur em background
    start_blur

    # 3. Espera / monitora entrada
    countdown

    # 4. Fade
    fade_out
    
    # 5. Restaura brilho antes do i3lock
    restore_brightness

    # 6. Aguarda blur terminar
    if [[ -n "$blur_pid" ]]; then
        wait "$blur_pid" 2>/dev/null || true
        blur_pid=""
    fi

    # 7. Bloqueia
    execute_lock
}

###############################################################################
# MAIN
###############################################################################

get_outputs
get_brightness

case "$MODE" in

    now)
        lock_now
        ;;

    normal)
        lock_normal
        ;;

esac

exit 0

