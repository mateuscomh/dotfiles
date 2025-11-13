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
BLUR_LEVEL="0x55"     # Nível de blur para o ImageMagick
TEMP_BG="/tmp/lockscreen.png"

# --- Variáveis Globais para PIDs em background ---
blur_pid=""
key_monitor_pid=""

# --- Funções ---

# Restaura o brilho original e limpa os processos/arquivos
cleanup() {
    if [[ -n "$XRANDR_RESTORE_CMD" ]]; then
        eval "$XRANDR_RESTORE_CMD" &>/dev/null || true
    fi
    if [[ -n "$blur_pid" ]] && kill -0 "$blur_pid" 2>/dev/null; then
        kill "$blur_pid"
    fi
    if [[ -n "$key_monitor_pid" ]] && kill -0 "$key_monitor_pid" 2>/dev/null; then
        # Matar o processo pai e seus filhos (xinput)
        pkill -P "$key_monitor_pid" 2>/dev/null || true
        kill "$key_monitor_pid"
    fi
 rm -f "$TEMP_BG"
 pkill -USR1 picom &>/dev/null || true # Retoma o picom
}

# Centraliza o comando i3lock-color
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

# Listener de teclado robusto
start_keyboard_listener() {
    local device_id
    device_id=$(xinput list |
        awk -F 'id=' '/liliums Lily58/ && !/Consumer Control|Mouse|System Control/ {print $2}' |
        awk '{print $1}')
    if [[ -z "$device_id" ]]; then
        echo "Aviso: Teclado 'liliums Lily58' não encontrado. Monitoramento de teclado desativado."
        return
    fi
    (stdbuf -oL xinput test "$device_id" | grep --line-buffered -q "^key press") &
    key_monitor_pid=$!
}

# --- Execução ---

# Registra a função de limpeza para ser executada na saída do script
trap cleanup EXIT SIGINT SIGTERM

# --- NOVA SEÇÃO: Análise de Parâmetros ---
# Verifica se o primeiro parâmetro ($1) foi fornecido
if [[ -n "$1" ]]; then
    # Se o parâmetro for um número inteiro positivo ou zero
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        FADE_SECONDS="$1"
    # Se o parâmetro for a string "now"
    elif [[ "$1" == "now" ]]; then
        FADE_SECONDS=0
    else
        echo "Parâmetro inválido: '$1'. Use 'now' ou um número em segundos."
        exit 1
    fi
fi

# Se o tempo de fade for 0 (por "now" ou pelo parâmetro 0), bloqueia imediatamente
if [[ "$FADE_SECONDS" -eq 0 ]]; then
    pkill -USR1 picom &>/dev/null || true
    scrot -o "$TEMP_BG"
    sleep 0.5
    convert "$TEMP_BG" -filter Gaussian -blur "$BLUR_LEVEL" "$TEMP_BG"
    execute_lock
    exit 0
fi
# --- FIM DA NOVA SEÇÃO ---

# 1. Obter brilho inicial e saídas de vídeo ativas
start_brightness=$(xrandr --verbose | grep -i brightness | awk '{print $2}' | head -n 1)
start_brightness=${start_brightness:-1.0}

mapfile -t outputs < <(xrandr --query | awk '/ connected / && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/{print $1}')

# Monta o comando para restaurar o brilho
XRANDR_RESTORE_CMD="xrandr"
for output in "${outputs[@]}"; do
    XRANDR_RESTORE_CMD+=" --output $output --brightness $start_brightness"
done

# 2. Capturar tela e iniciar blur em background
scrot -o "$TEMP_BG"
convert "$TEMP_BG" -filter Gaussian -blur "$BLUR_LEVEL" "$TEMP_BG" &
blur_pid=$!

# 3. Iniciar listener de teclado
start_keyboard_listener

# 4. Loop principal para escurecer e notificar
initial_pos=$(xdotool getmouselocation --shell)
steps=$((FADE_SECONDS * 20))
brightness_step=$(echo "($start_brightness / $steps)" | bc -l)
current_brightness=$start_brightness

for ((i = 0; i < steps; i++)); do
    # Detectar movimento do mouse
    if [[ "$(xdotool getmouselocation --shell 2>/dev/null || echo "$initial_pos")" != "$initial_pos" ]]; then
        dunstify -r 100 "Bloqueio cancelado por movimento."
        exit 0
    fi
    
    # Detectar tecla pressionada
    if [[ -n "$key_monitor_pid" ]] && ! kill -0 "$key_monitor_pid" 2>/dev/null; then
        dunstify -r 100 "Bloqueio cancelado por teclado."
        exit 0
    fi

    # Atualiza a notificação
    progress=$(((i + 1) * 100 / steps))
    dunstify --icon=preferences-desktop-screensaver \
        -h int:value:"$progress" \
        -h string:hlcolor:#8844ff \
        -h string:x-dunst-stack-tag:lock-progress \
        -r 500 "Bloqueando em breve..." "$(date '+%T')" || true

    # Diminui o brilho
    current_brightness=$(echo "$current_brightness - $brightness_step" | bc -l)
    xrandr_args=()
    for output in "${outputs[@]}"; do
        xrandr_args+=(--output "$output" --brightness "$current_brightness")
    done
    xrandr "${xrandr_args[@]}"

    sleep 0.05
done

# Espera o processo de blur terminar
wait "$blur_pid"

# Finalmente, executa o bloqueio
execute_lock
