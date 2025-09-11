#!/bin/bash

set -e

TMP_DIR="/tmp/discord_update"
DISCORD_URL="https://discord.com/api/download?platform=linux&format=deb"

mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "🔄 Baixando último .deb do Discord..."
curl -L -o discord.deb "$DISCORD_URL"

echo "📦 Instalando..."
sudo dpkg -i discord.deb || sudo apt -f install -y

echo "✅ Discord atualizado."

discord &
