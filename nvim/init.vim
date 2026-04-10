call plug#begin('~/.vim/plugged')
 Plug 'mboughaba/i3config.vim'
 Plug 'mg979/vim-visual-multi', {'branch': 'master'}
 Plug 'vim-airline/vim-airline'
" Plug 'scrooloose/Syntastic'
 Plug 'vim-airline/vim-airline-themes'
 Plug 'junegunn/vim-easy-align'
 Plug 'ekalinin/dockerfile.vim'
 Plug 'ryanoasis/vim-devicons' "Icones dev
 Plug 'sheerun/vim-polyglot' "Highligh de várias lang
 Plug 'Xuyuanp/nerdtree-git-plugin'
 Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
 Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
 Plug 'dense-analysis/ale'
 Plug 'jiangmiao/auto-pairs'
 Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
"Plug 'neovim/nvim-lspconfig'
call plug#end()

"------------Tema do nvim------------
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

if (has("nvim")) "Transparent background. Only for nvim
    highlight Normal guibg=NONE ctermbg=NONE
    highlight EndOfBuffer guibg=NONE ctermbg=Gray
    highlight Visual guibg=#5e8d87 ctermbg=LightYellow 
endif

"let g:sonokai_style = 'default'
"let g:sonokai_enable_italic = 1
"let g:sonokai_disable_italic_comment = 0
"let g:sonokai_diagnostic_line_highlight = 0
"let g:sonokai_current_word = 'bold'
"colorscheme default 
highlight CursorWord cterm=bold ctermbg=lightyellow guibg=#686b6d
highlight OtherWords cterm=NONE ctermbg=gray guibg=Gray    " Outras ocorrências

colorscheme catppuccin-frappe " catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha

"--------Cores de sintaxe--------
syntax enable
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'molokai'
let g:airline_powerline_fonts = 1

"-------- Vim heath check ------
let g:loaded_perl_provider = 0
let g:loaded_ruby_provider = 0

"----------Syntastic --------------
"let g:syntastic_check_on_open       = 0
"let g:syntastic_check_on_wq         = 0
"let g:syntastic_enable_perl_checker = 1
"let g:syntastic_perl_checkers      = ['perl','podchecker']
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

"--------Numero de linhas----------
set number
set relativenumber
set scrolloff=8

" ------!Insert Mode Relative-------
autocmd InsertEnter * set norelativenumber

" ------Insert Mode Relative-------
autocmd InsertLeave * set relativenumber

"------Nvim copy selection-------
set clipboard=unnamed
set guioptions+=a

"--------Adicionar interacao mouse--------
set mouse=a

"------Change Cursor Mode--------
let &t_SI="\e[6 q"
let &t_EI="\e[2 q"
let &t_SR="\e[4 q"

"----------Menu suspenso----------
set wildmenu
set wildmode=longest,full
set wildoptions=pum

"----------Cache arquivos----------
set hidden
set updatetime=100

"--------Pesquisa recursiva--------
set path+=**

"--------Definir titulo editor--------
set title

"--------Highlight em pesquisas--------
set hlsearch
set ignorecase
set smartcase
set incsearch
let @/ = ""
set inccommand=split

"--------Codificação--------
set encoding=utf-8
set nocompatible
set title
set cursorline
set ruler

"--------71 colunas----------
highlight ColorColumn ctermbg=gray
call matchadd('ColorColumn', '\%81v',100)

"-------Auto Complete--------
set complete+=kspell,w,b,u,i,t
set shortmess+=c
set completeopt=menuone,longest

"--------Caracteres Ocultos----------
set nolist
set listchars=tab:›-,space:·,trail:◀,eol:↲
set fillchars=vert:│,fold:-,eob:~

"--------Tabulacao----------
set tabstop=2
set shiftwidth=2
set expandtab
set softtabstop=2 
set autoindent
set smartindent

"--------Compatibilidade.py-----
au BufNewFile,BufRead *.py
        \ set tabstop=4     |
        \ set softtabstop=4 |
        \ set shiftwidth=4  |
        \ set textwidth=89  |
        \ set expandtab     |
        \ set autoindent    |
        \ set foldmethod=syntax
au BufNewFile *.py set fileformat=unix

"--------Remapear teclas----------
nnoremap <tab> :
"map j gj
"map k gk
"map <down> gj
"map <up> gk
"inoremap <down> <c-o>gj
"inoremap <up> <c-o>gk
nnoremap <silent> [ :normal O<CR>
nnoremap <silent> ] :normal o<CR>

"----- Nerdtree Options -----
" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
let NERDTreeShowHidden=1
nmap <silent> <Right> l
nmap <silent> <Left> h

"---- Funcoes macro ----
let mapleader="\<space>"
nnoremap <leader>; A;<esc>
nnoremap <leader>a :NERDTreeToggle<CR>
nnoremap <leader>n :tabnew<CR>
vnoremap <leader>/ :norm i#<CR>
vnoremap <leader>? :norm ^x<CR>
nnoremap <leader>? :silent s/^#//<CR>
nnoremap <leader>/ :silent s/^/#/<CR>:nohlsearch<CR>

"-----Copiar area de transf-------
vmap <silent> <leader>yy "+y
vmap <silent> <leader>dd "+c

"-----Executar o terminal-----
map <f7> :term bash %<cr>

"-----Go to last position-----
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
endif

"-----Terminal abaixo-----
set splitbelow

"----Alternar numeros de linhas------
map <F2> :set number!<cr>

"----Alternar numeros relativos----
map <F3> :set relativenumber!<cr>

"----Alternar caracteres invisíveis----
map <f4> :set list!<cr>

"-----Corretor ortografico-------
map <f5> :set spell!<cr>

"-----Alternar quebra de linha------
map <f6> :set wrap!<cr>

"-----Indentar visual mode----
vmap < <gv
vmap > >gv

" Habilita linters para cada linguagem
let g:ale_linters = {
\   'yaml': ['yamllint', 'kubeconform'],
\   'sh': ['shellcheck'],
\   'ansible': ['ansible_lint'],
\   'go': ['golangci-lint'],
\   'json': ['jsonlint'],
\   'vim': ['vimt']
\}

autocmd BufRead,BufNewFile *.yaml,*.yml set filetype=yaml
let g:ale_sign_error = '>>'       " Sinal para erros
let g:ale_yaml_kubeconform_options = '--strict'
let g:ale_sign_warning = '--'     " Sinal para avisos

"-----Selecao highlight palavras-----
"function! HighlightWordUnderCursor()
"    " Limpa os destaques anteriores
"    match none
""    2match none
"
"    " Verifica se o caractere sob o cursor não é pontuação ou espaço
"    if getline(".")[col(".")-1] !~# '[[:punct:][:blank:]]'
"        " Realça a palavra sob o cursor com 'CursorWord'
"        exec 'match CursorWord /\V\<'.expand('<cword>').'\>/'
"
"        " Realça as outras ocorrências com 'OtherWords'
""        exec '2match OtherWords /\V\<'.expand('<cword>').'\>/'
"    endif
"endfunction
"autocmd! CursorHold,CursorHoldI * call HighlightWordUnderCursor()
