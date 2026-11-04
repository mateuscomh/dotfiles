#!/usr/bin/env bash

###############################
#  Script para i3-lock com notificação e fade-out
#
# Uso:
#   ./script.sh         -> Bloqueia com o fade padrão
#   ./script.sh now      -> Bloqueia instantaneamente
#   ./script.sh <secs>  -> Bloqueia com um fade de <secs> segundos
#
# Requisitos:
# - i3lock-color, xrandr, xdotool, dunst, scrot, convert, xinput
# Version: 5.0.0
###############################

# Sair se um comando falhar
set -e

# Não executar se o i3lock já estiver rodando
if pgrep -x "i3lock" >/dev/null; then
    exit 0
fi

# --- Configurações ---
FADE_SECONDS=25       # Duração PADRÃO do efeito de fade em segundos
BLUR_LEVEL="0x5"      # Nível de blur para o ImageMagick
TEMP_BG="/tmp/lockscreen.png"
BRIGHTNESS_CHANGED=0

# --- Variáveis Globais para PIDs em background ---
blur_pid=""
key_monitor_pid=""
notif_pid=""

# --- Funções ---

cleanup() {
    # Restaura o brilho original silenciosamente
    if [[ "$BRIGHTNESS_CHANGED" -eq 1 ]] && [[ -n "$XRANDR_RESTORE_CMD" ]]; then
        eval "$XRANDR_RESTORE_CMD" &>/dev/null || true
    fi

    if [[ -n "$blur_pid" ]] && kill -0 "$blur_pid" 2>/dev/null; then
        kill "$blur_pid" 2>/dev/null || true
    fi
    if [[ -n "$key_monitor_pid" ]] && kill -0 "$key_monitor_pid" 2>/dev/null; then
        pkill -P "$key_monitor_pid" 2>/dev/null || true
        kill "$key_monitor_pid" 2>/dev/null || true
    fi
    # Mata o loop de notificação caso o script seja interrompido
    if [[ -n "$notif_pid" ]] && kill -0 "$notif_pid" 2>/dev/null; then
        kill "$notif_pid" 2>/dev/null || true
    fi
    rm -f "$TEMP_BG"
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
    (
        # Espera meio segundo para você tirar a mão do Enter ou do atalho do i3
        sleep 0.5
        # Escuta eventos de input na raiz do X11
        stdbuf -oL xinput test-xi2 --root 2>/dev/null |
        grep --line-buffered -q "RawKeyPress"
    ) &
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

# 1. Obter brilho inicial e saídas de vídeo ativas
start_brightness=$(xrandr --verbose | grep -i brightness | awk '{print $2}' | head -n 1)
start_brightness=${start_brightness:-1.0}

mapfile -t outputs < <(xrandr --query | awk '/ connected / && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/{print $1}')

XRANDR_RESTORE_CMD="xrandr"
for output in "${outputs[@]}"; do
    XRANDR_RESTORE_CMD+=" --output $output --brightness $start_brightness"
done

# Bloqueio Imediato (now)
if [[ "$FADE_SECONDS" -eq 0 ]]; then
    scrot -o "$TEMP_BG"
    OMP_NUM_THREADS=1 convert -limit thread 1 "$TEMP_BG" -scale 10% -filter Gaussian -blur "$BLUR_LEVEL" -scale 1000% "$TEMP_BG"
    execute_lock
    exit 0
fi

# 2. Capturar tela com segurança
scrot -o "$TEMP_BG"
sleep 0.05 

# 3. Iniciar blur em background de forma isolada (Ultra-leve)
(
    sleep 0.2
    OMP_NUM_THREADS=1 nice -n 19 convert -limit thread 1 "$TEMP_BG" -scale 10% -filter Gaussian -blur "$BLUR_LEVEL" -scale 1000% "$TEMP_BG"
) &
blur_pid=$!

# 4. Iniciar listener de teclado
start_keyboard_listener

# Pega a posição inicial do mouse agora, para monitorar desde o início
initial_pos=$(xdotool getmouselocation --shell)

# ==============================================================================
# FASE 1: AVISO PRÉVIO (Sem alterar o brilho)
# ==============================================================================
PRE_WAIT=9
pre_steps=$((PRE_WAIT * 4)) # 4 atualizações por segundo

for ((n = 0; n <= pre_steps; n++)); do
    # Validações de interrupção (Mouse)
    if [[ "$(xdotool getmouselocation --shell 2>/dev/null || echo "$initial_pos")" != "$initial_pos" ]]; then
        dunstify -r 500 "Bloqueio cancelado por movimento."
        exit 0
    fi
    
    # Validações de interrupção (Teclado)
    if [[ -n "$key_monitor_pid" ]] && ! kill -0 "$key_monitor_pid" 2>/dev/null; then
        dunstify -r 500 "Bloqueio cancelado por teclado."
        exit 0
    fi

    # Notificação de aviso (Barra amarela/laranja para diferenciar)
    progress=$((n * 100 / pre_steps))
    dunstify --icon=dialog-warning \
        -h int:value:"$progress" \
        -h string:hlcolor:#ffaa00 \
        -h string:x-dunst-stack-tag:lock-progress \
        -r 500 "Aviso de Bloqueio" || true
        
    sleep 0.25
done

# ==============================================================================
# FASE 2: FADE OUT (Escurecendo a tela - Sincronizado)
# ==============================================================================
BRIGHTNESS_CHANGED=1

# 5 passos por segundo (0.2s) reduz pela metade o estresse no X11/GPU mantendo a fluidez
steps=$((FADE_SECONDS * 5))

for ((i = 1; i <= steps; i++)); do
    # Validações de interrupção durante o fade
    if [[ "$(xdotool getmouselocation --shell 2>/dev/null || echo "$initial_pos")" != "$initial_pos" ]]; then
        dunstify -r 500 "Bloqueio cancelado por movimento."
        exit 0
    fi
    
    if [[ -n "$key_monitor_pid" ]] && ! kill -0 "$key_monitor_pid" 2>/dev/null; then
        dunstify -r 500 "Bloqueio cancelado por teclado."
        exit 0
    fi

    # Calcula o brilho com 2 casas decimais e ponto decimal fixo (evita bugs do bc -l)
    current_brightness=$(LC_NUMERIC=C awk -v start="$start_brightness" -v i="$i" -v s="$steps" 'BEGIN { printf "%.2f", start * (1 - (i / s)) }')
    
    # Evita chegar a 0.00 absoluto antes do lock (alguns monitores desligam o painel em 0.00)
    if [[ "$current_brightness" == "0.00" ]]; then
        current_brightness="0.05"
    fi

    xrandr_args=()
    for output in "${outputs[@]}"; do
        xrandr_args+=(--output "$output" --brightness "$current_brightness")
    done
    
    # Atualiza o brilho primeiro
    xrandr "${xrandr_args[@]}"

    # Atualiza a notificação apenas a cada 2 passos (0.4s) para não colidir com o xrandr
    if (( i % 2 == 0 || i == steps )); then
        progress=$((i * 100 / steps))
        dunstify --icon=preferences-desktop-screensaver \
            -h int:value:"$progress" \
            -h string:hlcolor:#8844ff \
            -h string:x-dunst-stack-tag:lock-progress \
            -r 500 "Escurecendo a tela..." "$(date '+%T')" || true
    fi

    sleep 0.2
done

# Garante que o blur terminou antes de subir o i3lock
wait "$blur_pid"

# Executa o bloqueio final
execute_lock
