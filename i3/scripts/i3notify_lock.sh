#!/usr/bin/env bash

###############################
#  Script para i3-lock com notificação, fade-out e parâmetros
#
# Uso:
#   ./script.sh         -> Bloqueia com o fade padrão
#   ./script.sh now     -> Bloqueia instantaneamente
#   ./script.sh <secs>  -> Bloqueia com um fade de <secs> segundos
#
# Requisitos:
# - i3lock-color, xrandr, xdotool, dunst, scrot, convert, xinput
# Version: 4.7.0
###############################

# Sair se um comando falhar
set -e

# Não executar se o i3lock já estiver rodando
if pgrep -x "i3lock" >/dev/null; then
    exit 0
fi

# --- Configurações ---
FADE_SECONDS=20       # Duração PADRÃO do efeito de fade em segundos
BLUR_LEVEL="0x5"     # Nível de blur para o ImageMagick
TEMP_BG="/tmp/lockscreen.png"

# --- Variáveis Globais para PIDs em background ---
blur_pid=""
key_monitor_pid=""

# --- Funções ---

cleanup() {
    # Restaura o brilho original silenciosamente
    if [[ -n "$XRANDR_RESTORE_CMD" ]]; then
        eval "$XRANDR_RESTORE_CMD" &>/dev/null || true
    fi
    if [[ -n "$blur_pid" ]] && kill -0 "$blur_pid" 2>/dev/null; then
        kill "$blur_pid"
    fi
    if [[ -n "$key_monitor_pid" ]] && kill -0 "$key_monitor_pid" 2>/dev/null; then
        pkill -P "$key_monitor_pid" 2>/dev/null || true
        kill "$key_monitor_pid"
    fi
    rm -f "$TEMP_BG"
    
    # REMOVIDO: pkill -USR1 picom. 
    # Deixe o picom rodando. O i3lock-color lida bem com a tela cheia.
}

execute_lock() {
    i3lock -i "$TEMP_BG" \
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

start_keyboard_listener() {
    (stdbuf -oL xinput test-xi2 --root | grep --line-buffered -q "RawKeyPress") &
    key_monitor_pid=$!
}

# --- Execução ---

trap cleanup EXIT SIGINT SIGTERM

# Análise de Parâmetros
if [[ -n "$1" ]]; then
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        FADE_SECONDS="$1"
    elif [[ "$1" == "now" ]]; then
        FADE_SECONDS=0
    else
        echo "Parâmetro inválido: '$1'. Use 'now' ou um número em segundos."
        exit 1
    fi
fi

# 1. Obter brilho inicial e saídas de vídeo ativas (Mapeamento antecipado)
start_brightness=$(xrandr --verbose | grep -i brightness | awk '{print $2}' | head -n 1)
start_brightness=${start_brightness:-1.0}

mapfile -t outputs < <(xrandr --query | awk '/ connected / && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/{print $1}')

XRANDR_RESTORE_CMD="xrandr"
for output in "${outputs[@]}"; do
    XRANDR_RESTORE_CMD+=" --output $output --brightness $start_brightness"
done

# Bloqueio Imediato
if [[ "$FADE_SECONDS" -eq 0 ]]; then
    scrot -o "$TEMP_BG"
    convert "$TEMP_BG" -scale 10% -filter Gaussian -blur "$BLUR_LEVEL" -scale 1000% "$TEMP_BG"
    execute_lock
    exit 0
fi

# 2. Capturar tela com segurança
scrot -o "$TEMP_BG"
sleep 0.1 # Dá um respiro para o X11 terminar de desenhar o scrot

# 3. Iniciar blur em background reduzindo o peso da thread (usando nice)
nice -n 10 convert "$TEMP_BG" -scale 10% -filter Gaussian -blur "$BLUR_LEVEL" -scale 1000% "$TEMP_BG" &
blur_pid=$!

# 4. Iniciar listener de teclado
start_keyboard_listener

# 5. Loop principal (Otimizado para X11)
initial_pos=$(xdotool getmouselocation --shell)
# Reduzi as interações pela metade (10 FPS) para não engasgar o xrandr
steps=$((FADE_SECONDS * 10)) 
brightness_step=$(echo "($start_brightness / $steps)" | bc -l)
current_brightness=$start_brightness

for ((i = 0; i < steps; i++)); do
    if [[ "$(xdotool getmouselocation --shell 2>/dev/null || echo "$initial_pos")" != "$initial_pos" ]]; then
        dunstify -r 100 "Bloqueio cancelado por movimento."
        exit 0
    fi
    
    if [[ -n "$key_monitor_pid" ]] && ! kill -0 "$key_monitor_pid" 2>/dev/null; then
        dunstify -r 100 "Bloqueio cancelado por teclado."
        exit 0
    fi

    progress=$(((i + 1) * 100 / steps))
    dunstify --icon=preferences-desktop-screensaver \
        -h int:value:"$progress" \
        -h string:hlcolor:#8844ff \
        -h string:x-dunst-stack-tag:lock-progress \
        -r 500 "Bloqueando em breve..." "$(date '+%T')" || true

    current_brightness=$(echo "$current_brightness - $brightness_step" | bc -l)
    
    xrandr_args=()
    for output in "${outputs[@]}"; do
        xrandr_args+=(--output "$output" --brightness "$current_brightness")
    done
    
    xrandr "${xrandr_args[@]}"
    
    # Pausa maior (0.1s) evita sobrecarga no xrandr e engasgos visuais
    sleep 0.1 
done

# Espera o processo de blur terminar
wait "$blur_pid"

# Finalmente, executa o bloqueio
execute_lock
