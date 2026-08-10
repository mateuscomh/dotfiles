#!/bin/bash

# 1. Cria um array dinâmico com os nomes de todas as saídas (sinks) conectadas
SINKS=($(pactl list short sinks | awk '{print $2}'))
TOTAL_SINKS=${#SINKS[@]}

# Se houver apenas 1 dispositivo (ou nenhum), encerra sem fazer nada
if [ "$TOTAL_SINKS" -le 1 ]; then
    notify-send "Troca de Áudio" "Apenas um dispositivo disponível." -t 2000
    exit 0
fi

# 2. Descobre qual é a saída ativa no momento
CURRENT_SINK=$(pactl get-default-sink)

# 3. Acha a posição (índice) da saída atual dentro do nosso array
CURRENT_INDEX=-1
for i in "${!SINKS[@]}"; do
    if [ "${SINKS[$i]}" == "$CURRENT_SINK" ]; then
        CURRENT_INDEX=$i
        break
    fi
done

# Se por algum motivo a saída atual não estiver na lista, define o índice como 0
if [ "$CURRENT_INDEX" -eq -1 ]; then
    CURRENT_INDEX=0
fi

# 4. Calcula qual é a próxima saída da lista (usa módulo para voltar ao início se chegar no fim)
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL_SINKS ))
NEXT_SINK="${SINKS[$NEXT_INDEX]}"

# 5. Define a nova saída como padrão
pactl set-default-sink "$NEXT_SINK"

# 6. Move todos os fluxos de áudio que já estão tocando para a nova saída
for app in $(pactl list short sink-inputs | awk '{print $1}'); do
    pactl move-sink-input "$app" "$NEXT_SINK" 2>/dev/null
done

# 7. Busca o "nome amigável" (Description) da placa/fone para exibir na notificação
SINK_DESC=$(pactl list sinks | grep -A 10 "Name: $NEXT_SINK" | grep "Description:" | head -n 1 | sed -e 's/^[ \t]*Description:[ \t]*//')

# Fallback caso não consiga extrair a descrição
if [ -z "$SINK_DESC" ]; then
    SINK_DESC="$NEXT_SINK"
fi

# 8. Notifica na tela
notify-send "Áudio Alterado" "$SINK_DESC" -t 2000
