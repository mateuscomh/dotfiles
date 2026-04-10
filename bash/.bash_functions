#!/usr/bin/env bash

# functions for colorized output
# ANSI escape color codes
if [[ -z "${ansiRed}" ]]; then
	readonly ansiRed='\e[1;31m'
	readonly ansiGreen='\e[1;32m'
	readonly ansiYellow='\e[1;33m'
	readonly ansiNoColor='\e[0m'
fi

echord() {
	echo -e "${ansiRed}$*${ansiNoColor}"
}

echogr() {
	echo -e "${ansiGreen}$*${ansiNoColor}"
}

echoyl() {
	echo -e "${ansiYellow}$*${ansiNoColor}"
}

err() {
	echoRed "$*" >&2
}

warn() {
	echoYellow "$*" >&2
}
#-----------------------

# dud(): get the disk usage of a directory and its subdirs
dud() {
	du --max-depth=1 --human-readable "${@:-.}" | sort --human-numeric-sort
}
#-----------------------

# putclip: sends the clipboard to output
putclip() {
	xclip -selection clipboard -o
}
#--------------------

# getclip: spits the clipboard on stdout
getclip() {
	xclip -selection clipboard <<<"$*"
}
#-----------------------

# tla/tlr: Funções para lista de tarefas (ToDo)
export TODO="${HOME}/.todo.txt"
[ ! -f "$TODO" ] && touch "$TODO"
tla() { [ "$#" -eq 0 ] && echo "------" || echo "$(echo $* | md5sum | cut -c 1-3) → $(date +"%d-%m-%y %H:%M") • $* " >>$TODO && cat $TODO; }
tlr() { [ $# -eq 0 ] && echo "------" || sed -i "/^$*/d" $TODO && cat $TODO; }
#-----------------------

# lauch(): launch a aplication from terminal
launch() {
	case "$OSTYPE" in
	"cygwin"*)
		cygstart "$@"
		;;
	"darwin"*) # MacOS
		open "$@"
		;;
	*)
		xdg-open "$@"
		;;
	esac
}
#-----------------------

# Função 'gd' para navegação rápida entre diretórios
# gd em https://codeberg.org/blau_araujo/gd-function
gd() {
	local sel dir dirs dirs_hist dirs_home IFS fzf
	fzf=(
		fzf
		--reverse -e -i -1
		--prompt='📂 Ir para: '
		--height=15%
		--border=horizontal
		--info=inline
	)

	[[ $# -le 1 ]] || {
		echo 'gd: Excesso de argumentos!' 1>&2
		return 1
	}

	dir="${1:-$HOME}"

	case "$dir" in
	-) dir="" ;;
	--)
		# O segredo aqui é o -not -path '*/.*' para remover ocultas
		dir=$(find "$HOME" -maxdepth 5 \
			-type d \( -name ".git" -o -name "node_modules" -o -name ".*" \) -prune \
			-o -type d -print 2>/dev/null | "${fzf[@]}" || return 0)
		;;
	esac

	if [[ -d "$dir" ]]; then
		pushd "$dir" >/dev/null && {
			echo -e "\033[1;32m➜\033[0m $(pwd)"
			return
		}
	fi

	# Busca rápida (histórico + home) ignorando o lixo
	dirs_hist=$(dirs -l -p | grep -i "$dir")
	dirs_home=$(find ~ -maxdepth 3 \
		-type d \( -name ".git" -o -name "node_modules" -o -name ".*" \) -prune \
		-o -type d -iname "*$dir*" -print 2>/dev/null)

	IFS=$'\n'
	dirs=(
		${dirs_hist:+"$dirs_hist"}
		${dirs_home:+"$dirs_home"}
	)

	if ((${#dirs[@]} == 0)); then
		echo "gd: '$dir': Diretório não encontrado" 1>&2
		return 2
	fi

	sel=$(printf '%s\n' "${dirs[@]}" | awk '!i[$0]++' | "${fzf[@]}" || return 0)

	if [[ -n "$sel" ]]; then
		pushd "$sel" >/dev/null
		echo -e "\033[1;32m➜\033[0m $(pwd)"
	fi
}
complete -F _cd gd
#-----------------------

# urlencode
###########
# URL encode using pure bash.
#
# Inspiration:
# https://github.com/dylanaraps/pure-bash-bible#percent-encode-a-string

urlencode() {
	local LC_ALL=C
	local string="${*:-$(cat)}"
	local length="${#string}"
	local char

	for ((i = 0; i < length; i++)); do
		char="${string:i:1}"
		if [[ "$char" == [a-zA-Z0-9.~_-] ]]; then
			printf "$char"
		else
			printf '%%%02X' "'$char"
		fi
	done
	printf '\n'
}

urldecode() {
	local encoded="${*:-$(cat)}"
	encoded="${encoded//+/ }"
	printf '%b' "${encoded//%/\\x}"
	printf '\n'
}

# google(): Open google.com in the default browser, arguments are used as search terms.
google() {
	local terms
	terms="$(urlencode "$@")"
	launch "https://www.google.com/search?q=${terms}"
}
#-----------------------

# deduplicates: Check in folder if have files duplicates.
deduplicates() {
	local path="${1:-.}"
	local depth="${2:-1}"
	echo "🔍 Procurando por arquivos duplicados com base em MD5..."
	echo "📂 Diretório alvo: $path"
	echo "📏 Profundidade máxima: $depth"
	echo "⏳ Calculando hashes MD5 e buscando duplicatas..."

	find "$path" -maxdepth "$depth" -type f -exec md5sum '{}' \; | sort | uniq -Dw 32
	echo "✅ Busca concluída! Se houver duplicatas, elas serão listadas acima."
}

transfer() {
    local url="${TRANSFER_URL:-http://blade.local:9997}"
    local file
    local file_name

    # detecta clipboard automaticamente
    copy_clipboard() {
        if command -v xclip >/dev/null 2>&1; then
            xclip -selection clipboard
        elif command -v wl-copy >/dev/null 2>&1; then
            wl-copy
        elif command -v pbcopy >/dev/null 2>&1; then
            pbcopy
        else
            cat >/dev/null
        fi
    }

    # gera nome simples
    gen_name() {
        date +%s
    }

    uploadFile() {
        curl -s --upload-file "-" "${url}/${file_name}" \
            | tee >(copy_clipboard)
    }

    if [ $# -eq 0 ]; then
        echo -e "Usage:\n  transfer <file|directory>\n  ... | transfer <file_name>" >&2
        return 1
    fi

    if tty -s; then
        file="$1"

        if [ ! -e "$file" ]; then
            echo "$file: No such file or directory" >&2
            return 1
        fi

        # nome simples + extensão (se existir)
        ext="${file##*.}"
        if [ "$file" = "$ext" ]; then
            file_name="$(gen_name)"
        else
            file_name="$(gen_name).${ext}"
        fi

        if [ -d "$file" ]; then
            file_name="$(gen_name).zip"
            (cd "$file" && zip -r -q - .) | uploadFile
        else
            uploadFile <"$file"
        fi
    else
        file_name="$(gen_name)"
        uploadFile
    fi

    echo
}

# Compacta diretório em zip
zipdir() {
	dir="${1%/}"
	base="$(basename "$dir")"
	parent="$(dirname "$dir")"
	outfile="${parent}/${base}.zip"

	(
		cd "$parent" || exit 1
		zip -rv "$outfile" "$base"
	)

	abs_outfile=$(readlink -f "$outfile")
	echo "Arquivo salvo em: $abs_outfile"
}

# Extrai vários formatos
extract() {
	if [ -f "$1" ]; then
		run() {
			"$@" || {
				echo "Erro ao extrair $1"
				return 1
			}
		}

		case "$1" in
		*.tar.bz2) run tar xvjf "$1" ;;
		*.tar.gz) run tar xvzf "$1" ;;
		*.tar.xz) run tar xvJf "$1" ;;
		*.bz2) run bunzip2 -k "$1" ;;
		*.gz) run gunzip -k "$1" ;;
		*.tar) run tar xvf "$1" ;;
		*.tbz2) run tar xvjf "$1" ;;
		*.tgz) run tar xvzf "$1" ;;
		*.zip) run unzip -n "$1" ;;
		*.rar) run unrar x -o- "$1" ;;
		*.7z) run 7z x -aos "$1" ;;
		*.xz) run xz -dk "$1" ;;
		*) echo "Formato não suportado: $1" ;;
		esac
	else
		echo "Arquivo inválido: $1"
	fi
}

#Executa varios comandos em linha
runx() {
	for cmd in "$@"; do
		eval "$cmd"
	done
}

#Funcao recorte de ip do host
ipa() {
	ip -4 -o addr show | awk '{print $2 ": " $4}'
}

#Funcao criar pasta e entrar
mkd() {
	mkdir -p "$1" && cd "$1" || {
		echo "Erro ao entrar no diretório: $1" >&2
		return 1
	}
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd <"$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

#Navega com cd -[0-9] para retornar diretorios
cd() {
	if [[ $1 =~ ^-([0-9]+)$ ]]; then
		builtin cd "$(printf '../%.0s' $(seq 1 "${BASH_REMATCH[1]}"))"
	else
		builtin cd "$@"
	fi
}


rget() {
  if [ $# -lt 2 ]; then
    echo "Uso: rget <host> </caminho/remoto> [destino]"
    return 1
  fi

  HOST="$1"
  REMOTE_PATH="$2"
  DEST="${3:-.}"

  rsync -avz --progress "$HOST:$REMOTE_PATH" "$DEST"
}

docker-clean() {
  docker system prune -af --volumes
}

serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

cheat() {
  curl -s "https://cheat.sh/$1"
}
