#!/usr/bin/env bash

###############################
#  Script para i3-lock com notificação com detecção atividade mouse/teclado
#
# Descrição:
# - Exibe notificação com barra de progresso antes de bloquear a tela.
# - Cancela o bloqueio se houver movimento do mouse ou pressionamento de teclas.
#
# Requisitos:
# - xrandr, xdotool, dunst, i3lock, scrot, convert, awk, xinput, grep.
# Version: 3.3.2
###############################
set -e

if pgrep -x "i3lock" >/dev/null; then
	exit 0
fi

start_brightness=$(xrandr --verbose | grep -i brightness | awk '{print $2}' | head -n 1)
end_brightness=0.1
steps=60
TEMP_BG="/tmp/lockscreen.png"
initial_pos=$(xdotool getmouselocation --shell | grep -E 'X|Y' | cut -d '=' -f2)

# Obter a lista de saídas conectadas e ativas
get_active_outputs() {
	xrandr --query | awk '/ connected / && /[0-9]+mm x [0-9]+mm$/ { 
      print $1 
  }'
}

mapfile -t outputs < <(get_active_outputs)

# Função: Restaurar brilho original e sair
restore_brightness() {
	for output in "${outputs[@]}"; do
		# Obtém o brilho atual do monitor
		current_brightness=$(xrandr --verbose | grep -A 10 "^$output" | grep "Brightness" | awk '{print $2}')

		# Apenas altera o brilho se for diferente do valor inicial
		if [[ "$current_brightness" != "$start_brightness" ]]; then
			xrandr --output "$output" --brightness "$start_brightness"
		fi
	done
	cleanup
	exit 0
}

cleanup() {
	if [ -n "$TEMP_BG" ] && [ -f "$TEMP_BG" ]; then
		rm -f "$TEMP_BG"
	fi
	pkill -P $$
}

# Função: Detectar movimento do mouse
check_mouse_movement() {
	current_pos=$(xdotool getmouselocation --shell | grep -E 'X|Y' | cut -d '=' -f2)
	if [[ "$current_pos" != "$initial_pos" ]]; then
		restore_brightness
	fi
}

# Função: Obter interrupcao por teclado
check_key_press() {
	local device_id
	device_id=$(xinput list |
		awk -F 'id=' '/liliums Lily58/ && !/Consumer Control|Mouse|System Control/ {print $2}' |
		awk '{print $1}')
	if [[ -z "$device_id" ]]; then
		return
	fi
	while :; do
		xinput test "$device_id" | grep -q "key press" && restore_brightness
	done
}

check_key_press &
key_monitor_pid=$!

trap restore_brightness EXIT SIGINT SIGTERM SIGHUP SIGABRT SIGUSR1

# Notifica bloqueio de tela
current=0
while [ "$current" -le 100 ]; do
	dunstify --icon preferences-desktop-screensaver \
		-h int:value:"$current" \
		-h 'string:hlcolor:#ff4444' \
		-h string:x-dunst-stack-tag:progress-lock \
		--timeout=1500 "Bloqueio de Tela ..." "$(date '+%H:%M:%S %d/%m/%Y')"
	current=$((current + 1))
	sleep 0.15
	check_mouse_movement
	if ! kill -0 $key_monitor_pid 2>/dev/null; then
		kill "$key_monitor_pid"
	fi
done

brightness_step=$(echo "($start_brightness - $end_brightness) / $steps" | bc -l)
current_brightness=$start_brightness

calculate_progress() {
    echo "($(echo "scale=2; ($current_brightness - $end_brightness) / ($start_brightness - $end_brightness) * 100" | bc -l)/1)" | bc
}

# Aplica o brilho inicial imediatamente
xrandr_cmd=""
for output in "${outputs[@]}"; do
    xrandr_cmd+=" --output $output --brightness $current_brightness"
done
eval xrandr "$xrandr_cmd"

# Loop para diminuir o brilho gradualmente
while (($(echo "$current_brightness > $end_brightness" | bc -l))); do
#    # Ajusta o brilho para todos os monitores em um único comando
    xrandr_cmd=""
    for output in "${outputs[@]}"; do
        xrandr_cmd+=" --output $output --brightness $current_brightness"
    done
    eval xrandr "$xrandr_cmd"
    current=$(calculate_progress)

    dunstify --icon preferences-desktop-screensaver \
        -h int:value:"$current" \
        -h 'string:hlcolor:#ff4444' \
        -h string:x-dunst-stack-tag:progress-lock \
        -r 1000 \
        -t 900 \
        -u low \
        "Bloqueando..." "$(date '+%H:%M:%S %d/%m/%Y')"

    current_brightness=$(echo "$current_brightness - $brightness_step" | bc -l)
    sleep 0.2
    check_mouse_movement
    if ! kill -0 $key_monitor_pid 2>/dev/null; then
        kill "$key_monitor_pid"
    fi
done

sleep 1.0
check_mouse_movement
kill $key_monitor_pid 2>/dev/null
scrot $TEMP_BG
convert $TEMP_BG -filter Gaussian -blur 0x55 $TEMP_BG

# Bloqueia a tela com i3lock-color
i3lock -i $TEMP_BG \
	--clock \
	--indicator \
	--line-uses-ring \
	--time-color=#A659DE \
	--date-color=#B077D9 \
	--ring-color=#000000 \
	--ring-width=2 \
	--verif-text="and..."

# Restaura o brilho original
restore_brightness
