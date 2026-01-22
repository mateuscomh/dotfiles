#!/bin/bash

# Configurações
TMP_DIR="/tmp/discord_update"
DISCORD_URL="https://discord.com/api/download?platform=linux&format=deb"

# 1. Localizar arquivo de versão
SEARCH_PATHS=(
    "/usr/share/discord/resources/build_info.json"
    "/opt/discord/resources/build_info.json"
)

BUILD_INFO=""
for path in "${SEARCH_PATHS[@]}"; do
    [ -f "$path" ] && BUILD_INFO="$path" && break
done

# 2. Obter e limpar versão local (remove espaços e aspas)
if [ -n "$BUILD_INFO" ]; then
    LOCAL_VERSION=$(grep -oP '"version":\s*"\K[^"]+' "$BUILD_INFO" | tr -d '[:space:]')
else
    LOCAL_VERSION="0.0.0"
fi

# 3. Obter e limpar versão remota
# O 'tr -cd' garante que fiquem APENAS números e pontos
REMOTE_URL=$(curl -sIL -o /dev/null -w '%{url_effective}' "$DISCORD_URL")
REMOTE_VERSION=$(echo "$REMOTE_URL" | grep -oP '\d+\.\d+\.\d+' | head -n1 | tr -d '[:space:]')

echo "🔍 Versão local instalada: [$LOCAL_VERSION]"
echo "🌐 Versão remota no servidor: [$REMOTE_VERSION]"

# 4. Comparação Estrita
if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ] && [ -n "$LOCAL_VERSION" ]; then
    echo "✅ As versões coincidem. O Discord já está atualizado."
    exit 0
fi

# --- Início da atualização ---
echo "🚀 Nova versão detectada ou inconsistente! Iniciando..."

# 5. Verificar instâncias ativas
if pgrep -x "Discord" > /dev/null; then
    echo "⚠️  Fechando instâncias ativas do Discord..."
    pkill -15 Discord || pkill -9 Discord
    sleep 1
fi

mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "📥 Baixando v$REMOTE_VERSION..."
curl -L -o discord.deb "$REMOTE_URL"

echo "📦 Instalando..."
sudo apt install -y ./discord.deb

rm -rf "$TMP_DIR"
echo "✅ Processo finalizado com sucesso!"
