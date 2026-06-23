#!/usr/bin/env bash

# Configurações
CACHE_FILE="/tmp/weather_cache.txt"
CACHE_TIMEOUT=60          # Cache do clima em segundos
LOC_CACHE_FILE="/tmp/weather_location.txt"
LOC_CACHE_TIMEOUT=3600    # Cache da localização em segundos (1 hora)

# Função para detectar a localização dinamicamente via IP
# Prioridade: 1) variável WEATHER_LOCATION  2) cache  3) ipinfo.io  4) vazio (auto-detect do wttr.in)
get_location() {
    # Override manual via variável de ambiente
    if [[ -n $WEATHER_LOCATION ]]; then
        echo "$WEATHER_LOCATION"
        return
    fi

    # Verifica cache da localização
    if [[ -f $LOC_CACHE_FILE ]]; then
        local loc_age=$(($(date +%s) - $(stat -c %Y "$LOC_CACHE_FILE")))
        if [[ $loc_age -lt $LOC_CACHE_TIMEOUT ]]; then
            cat "$LOC_CACHE_FILE"
            return
        fi
    fi

    # Detecta cidade via ipinfo.io
    local city
    city=$(curl -s --max-time 5 "ipinfo.io/city" 2>/dev/null)

    if [[ -n $city && ! $city =~ html && ! $city =~ error && ! $city =~ \{ ]]; then
        echo "$city" > "$LOC_CACHE_FILE"
        echo "$city"
        return
    fi

    # Fallback: string vazia faz o wttr.in auto-detectar pelo IP
    echo ""
}

# Função para obter informações do clima
get_weather_info() {
    local location result result1

    location=$(get_location)

    # Obtém o clima do wttr.in com timeout de 10 segundos
    result=$(curl -s --max-time 10 "wttr.in/${location}?format=1" | sed 's/ //g') && \
    result1=$(curl -s --max-time 10 "wttr.in/${location}?format=%m")

    # Verifica se a resposta é válida
    if [[ -z $result || $result =~ Unknown || $result =~ html || ! $result =~ [0-9]+°C ]]; then
        echo "wttr.in indisponível ou resposta inválida. Tentando API alternativa..." >&2

        # Tenta obter o clima da API alternativa
        result=$(curl -s --max-time 10 "https://api.wsclima.com.br/v1/stations/1223/detail" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" | \
            grep -oP '"temp":"\K[0-9]+\.[0-9]+' | head -n 1)

        # Adiciona o símbolo de grau Celsius à temperatura
        if [[ -n $result ]]; then
            result="${result}°C"
        else
            result="N/A"
        fi
    else
        # Adiciona o ícone da fase lunar apenas quando wttr.in respondeu corretamente
        result="${result1}${result}"
    fi

    echo "$result"
}

# Função para obter o dia da semana
get_day_of_week() {
    LC_TIME=pt_BR.UTF-8 date +%a
}

# Função principal
main() {
    local output_file="${HOME}/scripts/Output/i3clima"
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
    mkdir -p "$(dirname "$output_file")"
    echo "$weather_info.$day_of_week" > "$output_file"
}

# Executa o script
main

