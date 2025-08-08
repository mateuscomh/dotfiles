#!/usr/bin/env bash

# Configurações
CACHE_FILE="/tmp/weather_cache.txt"
CACHE_TIMEOUT=60  # Tempo de cache em segundos
#WEATHER_FORMAT="%m %c+%t"

# Função para obter informações do clima
get_weather_info() {
    local result
    local result1

    # Obtém o clima do wttr.in com timeout de 10 segundos
    result=$(curl -s --max-time 10 "wttr.in?format=1" | sed 's/ //g') && \
    result1=$(curl -s --max-time 10 "wttr.in/Juiz+de+Fora?format=%m")

    # Verifica se a resposta é válida
    if [[ -z $result || $result =~ "Unknown" || $result =~ "html" || ! $result =~ [0-9]+°C ]]; then
        echo "wttr.in indisponível ou resposta inválida. Tentando API alternativa..." >&2
        result1=""

        # Tenta obter o clima da API alternativa
        sleep 3
        result=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=-21.7642&longitude=-43.3503&current=temperature_2m&timezone=America%2FSao_Paulo" \
            | jq -r '.current.temperature_2m')

        # Adiciona o símbolo de grau Celsius à temperatura
        if [[ -n $result ]]; then
            result="${result1}${result}°C"
        else
            result=""
        fi
    fi

    echo "$result1$result"
}

# Função para obter o dia da semana
get_day_of_week() {
    LC_TIME=pt_BR.UTF-8 date +%a
}

# Função principal
main() {
    local output_file="/home/salaam/scripts/Output/i3clima"
    local weather_info
    local day_of_week

    # Verifica se o cache é válido
    if [[ -f $CACHE_FILE ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
        if [[ $cache_age -lt $CACHE_TIMEOUT ]]; then
            weather_info=$(cat "$CACHE_FILE")
        else
            weather_info=$(get_weather_info)
            [[ $weather_info != "N/A" ]] && echo "$weather_info" > "$CACHE_FILE"
        fi
    else
        weather_info=$(get_weather_info)
        [[ $weather_info != "N/A" ]] && echo "$weather_info" > "$CACHE_FILE"
    fi

    # Se não conseguiu obter uma resposta válida, usa o cache anterior
    [[ -z $weather_info || $weather_info == "N/A" ]] && weather_info=$(cat "$CACHE_FILE" 2>/dev/null || echo "N/A")

    # Obtém o dia da semana
    day_of_week=$(get_day_of_week)

    # Salva o resultado no arquivo de saída
    echo "$weather_info.$day_of_week" > "$output_file"
}

# Executa o script
main

