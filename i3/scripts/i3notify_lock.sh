#!/usr/bin/env bash

###############################################################################
# i3-smart-lock.sh
# Fluxo: Espera com progresso no Dunst -> Escurecimento Suave -> i3lock
###############################################################################

set -e

# Previne execuções em duplicidade
if pgrep -x "i3lock" >/dev/null; then
    exit 0
fi

# --- CONFIGURAÇÕES ---
WAIT_SECONDS=${1:-15}    # Tempo de aviso (padrão 15s)
FADE_SECONDS=15           # Tempo de fade out
MIN_BRIGHTNESS=20        # Brilho mínimo em % (20% evita que monitores HDMI apaguem)
BLUR_LEVEL="0x5"
TEMP_BG="/tmp/i3lock_screen.png"

# --- VARIÁVEIS DO SISTEMA ---
BRIGHT_CHANGED=0
blur_pid=""
key_pid=""
initial_mouse=""

# Descobre saídas conectadas de uma só vez
mapfile -t OUTPUTS < <(xrandr --query | awk '/ connected / && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/{print $1}')

# Captura brilho atual e formata como inteiro de 0 a 100
raw_bright=$(xrandr --verbose | grep -i brightness | awk '{print $2}' | head -n 1)
raw_bright=${raw_bright:-1.0}
START_BRIGHT=$(awk -v b="$raw_bright" 'BEGIN { printf "%d", b * 100 }')

# ARRAY DE RESTAURAÇÃO DO XRANDR (evita reescrever durante o script)
declare -a RESTORE_ARGS=()
for out in "${OUTPUTS[@]}"; do
    RESTORE_ARGS+=(--output "$out" --brightness "$raw_bright")
done

# --- FUNÇÕES ---

cleanup() {
    # Restaura o brilho apenas se alterado no decorrer do script
    if [[ "$BRIGHT_CHANGED" -eq 1 ]] && [[ ${#RESTORE_ARGS[@]} -gt 0 ]]; then
        xrandr "${RESTORE_ARGS[@]}" 2>/dev/null || true
    fi
    [[ -n "$blur_pid" ]] && kill -0 "$blur_pid" 2>/dev/null && kill "$blur_pid" 2>/dev/null || true
    if [[ -n "$key_pid" ]] && kill -0 "$key_pid" 2>/dev/null; then
        pkill -P "$key_pid" 2>/dev/null || true
        kill "$key_pid" 2>/dev/null || true
    fi
    rm -f "$TEMP_BG"
}

check_interrupt() {
    local curr_mouse
    curr_mouse=$(xdotool getmouselocation --shell 2>/dev/null || echo "$initial_mouse")
    if [[ "$curr_mouse" != "$initial_mouse" ]]; then
        dunstify -r 500 --urgency=low "Bloqueio cancelado pelo mouse."
        exit 0
    fi
    if [[ -n "$key_pid" ]] && ! kill -0 "$key_pid" 2>/dev/null; then
        dunstify -r 500 --urgency=low "Bloqueio cancelado pelo teclado."
        exit 0
    fi
}

start_keyboard_monitor() {
    (stdbuf -oL xinput test-xi2 --root | grep --line-buffered -q "RawKeyPress") &
    key_pid=$!
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

# --- FLUXO DE EXECUÇÃO ---

trap cleanup EXIT SIGINT SIGTERM

# Comando de bloqueio imediato "now"
if [[ "$WAIT_SECONDS" == "now" ]]; then
    maim "$TEMP_BG"
    OMP_NUM_THREADS=1 nice -n 19 convert -limit thread 1 "$TEMP_BG" -scale 10% -filter Gaussian -blur "$BLUR_LEVEL" -scale 1000% "$TEMP_BG"
    execute_lock
    exit 0
fi

# 1. Captura imagem da tela
maim "$TEMP_BG"

# 2. Executa Blur em Background (silencioso e sem disputar CPU)
(
    # Aguarda o maim liberar o disco e o sistema respirar antes de processar a imagem
    sleep 0.5
    OMP_NUM_THREADS=1 nice -n 19 convert -limit thread 1 "$TEMP_BG" -scale 10% -filter Gaussian -blur "$BLUR_LEVEL" -scale 1000% "$TEMP_BG"
) &
blur_pid=$!

# 3. Monitora entrada de dados
start_keyboard_monitor
initial_mouse=$(xdotool getmouselocation --shell)

# ==========================================
# FASE 1: AVISO E BARRA DE PROGRESSO
# ==========================================
if (( WAIT_SECONDS > 0 )); then
    steps=$(( WAIT_SECONDS * 4 )) # 4 verificações por segundo são mais leves que 10
    for (( i=0; i<=steps; i++ )); do
        check_interrupt
        if (( i % 4 == 0 )); then
            progress=$(( (i * 100) / steps ))
            dunstify --icon=preferences-desktop-screensaver \
                --urgency=low \
                -h int:value:"$progress" \
                -h string:hlcolor:#8844ff \
                -r 500 "Bloqueando em breve..." "$(date '+%T')" || true
        fi
        sleep 0.25
    done
fi

# ==========================================
# FASE 2: FADE-OUT SUAVE
# ==========================================
if (( FADE_SECONDS > 0 )); then
    BRIGHT_CHANGED=1
    
    # Atualiza a notificação de forma limpa (reaproveitando o ID 500)
    dunstify -r 500 --urgency=low "Escurecendo a tela..." "$(date '+%T')" || true
    
    # Pausa vital: dá tempo de o Picom renderizar a notificação antes do xrandr mexer na GPU
    sleep 0.50
    
    # 5 passos por segundo para fade out são fluidos e não enfileiram comandos do xrandr
    fade_steps=$(( FADE_SECONDS * 5 ))
    step_size=$(( (START_BRIGHT - MIN_BRIGHTNESS) / fade_steps ))
    
    # Previne divisão por zero se brilho inicial já for baixo
    (( step_size < 1 )) && step_size=1
    
    curr_bright=$START_BRIGHT

    for (( i=0; i<fade_steps; i++ )); do
        check_interrupt
        
        curr_bright=$(( curr_bright - step_size ))
        (( curr_bright < MIN_BRIGHTNESS )) && curr_bright=$MIN_BRIGHTNESS
        
        # Converte inteiro de volta para formato decimal (ex: 85 -> 0.85)
        decimal_bright=$(awk -v b="$curr_bright" 'BEGIN { printf "%.2f", b / 100 }')
        
        args=()
        for out in "${OUTPUTS[@]}"; do
            args+=(--output "$out" --brightness "$decimal_bright")
        done
        
        # O xrandr executa aqui sem acúmulo de requisições no X11
        xrandr "${args[@]}" 2>/dev/null || true
        
        sleep 0.20
    done
fi

# Restaura o brilho digital original suavemente ANTES do lockscreen
if [[ "$BRIGHT_CHANGED" -eq 1 ]]; then
    xrandr "${RESTORE_ARGS[@]}" 2>/dev/null || true
    BRIGHT_CHANGED=0
fi

# Aguarda conclusão do blur em segurança se ele ainda estiver processando
wait "$blur_pid" 2>/dev/null || true

# Aciona bloqueio visual
execute_lock
