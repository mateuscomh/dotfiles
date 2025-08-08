#!/usr/bin/env bash

###############################
#  Script para i3-lock com notificação e fade-out
#
# Requisitos:
# - xrandr, xdotool, dunst, i3lock, scrot, convert (ImageMagick), xinput
# Version: 4.5.1
###############################

# Sair imediatamente se um comando falhar
set -e

# Não executar se o i3lock já estiver rodando
if pgrep -x "i3lock" >/dev/null; then
	exit 0
fi

# --- Configurações ---
FADE_SECONDS=15   # Duração do efeito de fade em segundos
BLUR_LEVEL="0x55" # Nível de blur para o ImageMagick
TEMP_BG="/tmp/lockscreen.png"

# --- Funções ---

# Restaura o brilho original e limpa os processos/arquivos
cleanup() {
	if [[ -n "$XRANDR_RESTORE_CMD" ]]; then
		eval "$XRANDR_RESTORE_CMD"
	fi
	pkill -P $$
	rm -f "$TEMP_BG"
}

# Centraliza o comando i3lock
execute_lock() {
	i3lock -i "$TEMP_BG" \
		--clock \
		--indicator \
		--line-uses-ring \
		--time-color=#A659DE \
		--date-color=#B077D9 \
		--ring-color=#00000000 \
		--keyhl-color=#F299E1 \
		--verif-text="and.." \
		--wrong-text="" \
		--inside-color=00000000
}

start_keyboard_listener() {
	local device_id
	device_id=$(xinput list |
		awk -F 'id=' '/liliums Lily58/ && !/Consumer Control|Mouse|System Control/ {print $2}' |
		awk '{print $1}')
	(xinput test "$device_id" | grep -q "key press") &
}

trap cleanup EXIT SIGINT SIGTERM

# Verifica se o bloqueio deve ser instantâneo
if [[ "$1" == "now" ]]; then
	scrot -o "$TEMP_BG"
	convert "$TEMP_BG" -filter Gaussian -blur "$BLUR_LEVEL" "$TEMP_BG"
	execute_lock
	exit 0
fi

# 1. Obter brilho inicial e saídas de vídeo ativas
start_brightness=$(xrandr --verbose | grep -i brightness | awk '{print $2}' | head -n 1)
mapfile -t outputs < <(xrandr --query | awk '/ connected / && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/{print $1}')

# Monta o comando para restaurar o brilho, para ser usado depois de forma eficiente
XRANDR_RESTORE_CMD="xrandr"
for output in "${outputs[@]}"; do
	XRANDR_RESTORE_CMD+=" --output $output --brightness $start_brightness"
done

scrot -o "$TEMP_BG"

# 3. Iniciar os processos em segundo plano
convert "$TEMP_BG" -filter Gaussian -blur "$BLUR_LEVEL" "$TEMP_BG" &
blur_pid=$!

start_keyboard_listener
key_monitor_pid=$!

# 4. Loop principal para escurecer e notificar, enquanto detecta atividade
initial_pos=$(xdotool getmouselocation --shell)
steps=$((FADE_SECONDS * 20)) # 20 passos por segundo para uma animação suave
brightness_step=$(echo "($start_brightness / $steps)" | bc -l)
current_brightness=$start_brightness

for ((i = 0; i < steps; i++)); do
	# Detectar movimento do mouse
	if [[ "$(xdotool getmouselocation --shell)" != "$initial_pos" ]]; then
		dunstify -r 1001 "Bloqueio cancelado por movimento."
		exit 0
	fi
	# Detectar tecla pressionada
	if [[ -n "$key_monitor_pid" ]] && ! kill -0 "$key_monitor_pid" 2>/dev/null; then
		dunstify -r 50 "Bloqueio cancelado por teclado."
		exit 0
	fi

	progress=$(((i + 1) * 100 / steps))
	dunstify --icon=preferences-desktop-screensaver \
		-h int:value:"$progress" \
		-h string:hlcolor:#8844ff \
		-h string:x-dunst-stack-tag:lock-progress \
		-r 1001 "Bloqueando em breve..." "$(date '+%T')"

	current_brightness=$(echo "$current_brightness - $brightness_step" | bc -l)
	xrandr_cmd="xrandr"
	for output in "${outputs[@]}"; do
		xrandr_cmd+=" --output $output --brightness $current_brightness"
	done
	eval "$xrandr_cmd"
	sleep 0.05
done

wait "$blur_pid"

execute_lock
