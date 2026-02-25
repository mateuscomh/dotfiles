#!/bin/bash

# Script para organizar pasta Downloads
# Autor: Gerado para organização automática
# Data: 2026-01-28

# Configurações
DOWNLOADS_DIR="$HOME/Downloads"
LOG_FILE="$HOME/.organize_downloads.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para criar diretórios se não existirem
create_directories() {
    local dirs=(
        "Documentos"
        "Imagens"
        "Videos"
        "Audios"
        "Compactados"
        "Executaveis"
        "Codigo"
        "Planilhas"
        "Apresentacoes"
        "Outros"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$DOWNLOADS_DIR/$dir"
    done
}

# Função para registrar no log
log_action() {
    echo "[$DATE] $1" >> "$LOG_FILE"
}

# Função para mover arquivo
move_file() {
    local file="$1"
    local dest_dir="$2"
    local filename=$(basename "$file")
    
    # Verifica se o arquivo já existe no destino
    if [ -f "$dest_dir/$filename" ]; then
        # Adiciona timestamp ao nome se já existir
        local name="${filename%.*}"
        local ext="${filename##*.}"
        local timestamp=$(date +%Y%m%d_%H%M%S)
        
        if [ "$name" = "$filename" ]; then
            # Arquivo sem extensão
            filename="${name}_${timestamp}"
        else
            filename="${name}_${timestamp}.${ext}"
        fi
    fi
    
    mv "$file" "$dest_dir/$filename"
    echo -e "${GREEN}✓${NC} Movido: $(basename "$file") → $dest_dir"
    log_action "Movido: $file → $dest_dir/$filename"
}

# Função principal de organização
organize_downloads() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Organizador de Downloads${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Criar estrutura de diretórios
    create_directories
    
    # Contador de arquivos movidos
    local count=0
    
    # Iterar sobre arquivos na pasta Downloads (apenas arquivos, não diretórios)
    while IFS= read -r -d '' file; do
        # Pegar extensão do arquivo
        local ext="${file##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        
        local filename=$(basename "$file")
        
        # Ignorar arquivos ocultos e o próprio script
        if [[ "$filename" == .* ]] || [[ "$filename" == "organize_downloads.sh" ]]; then
            continue
        fi
        
        # Classificar e mover arquivos baseado na extensão
        case "$ext" in
            # Documentos
            pdf|doc|docx|odt|rtf|txt|md)
                move_file "$file" "$DOWNLOADS_DIR/Documentos"
                ((count++))
                ;;
            
            # Imagens
            jpg|jpeg|png|gif|bmp|svg|webp|ico|tiff|tif)
                move_file "$file" "$DOWNLOADS_DIR/Imagens"
                ((count++))
                ;;
            
            # Vídeos
            mp4|avi|mkv|mov|wmv|flv|webm|m4v|mpeg|mpg)
                move_file "$file" "$DOWNLOADS_DIR/Videos"
                ((count++))
                ;;
            
            # Áudios
            mp3|wav|flac|aac|ogg|m4a|wma|opus)
                move_file "$file" "$DOWNLOADS_DIR/Audios"
                ((count++))
                ;;
            
            # Compactados
            zip|rar|7z|tar|gz|bz2|xz|tgz|deb|rpm)
                move_file "$file" "$DOWNLOADS_DIR/Compactados"
                ((count++))
                ;;
            
            # Executáveis
            exe|msi|appimage|run|sh)
                move_file "$file" "$DOWNLOADS_DIR/Executaveis"
                ((count++))
                ;;
            
            # Código
            py|js|java|cpp|c|h|html|css|php|rb|go|rs|ts|jsx|tsx|vue)
                move_file "$file" "$DOWNLOADS_DIR/Codigo"
                ((count++))
                ;;
            
            # Planilhas
            xls|xlsx|ods|csv)
                move_file "$file" "$DOWNLOADS_DIR/Planilhas"
                ((count++))
                ;;
            
            # Apresentações
            ppt|pptx|odp)
                move_file "$file" "$DOWNLOADS_DIR/Apresentacoes"
                ((count++))
                ;;
            
            # Outros (arquivos sem extensão reconhecida)
            *)
                move_file "$file" "$DOWNLOADS_DIR/Outros"
                ((count++))
                ;;
        esac
        
    done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type f -print0)
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}Nenhum arquivo para organizar!${NC}"
    else
        echo -e "${GREEN}✓ Total de arquivos organizados: $count${NC}"
    fi
    echo -e "${BLUE}========================================${NC}"
    
    log_action "Organização concluída. Total de arquivos movidos: $count"
}

# Verificar se a pasta Downloads existe
if [ ! -d "$DOWNLOADS_DIR" ]; then
    echo -e "${YELLOW}Pasta Downloads não encontrada: $DOWNLOADS_DIR${NC}"
    exit 1
fi

# Executar organização
organize_downloads

# Mostrar relatório de pastas
echo ""
echo -e "${BLUE}Relatório de Espaço:${NC}"
du -sh "$DOWNLOADS_DIR"/* 2>/dev/null | sort -hr | head -10

exit 0
