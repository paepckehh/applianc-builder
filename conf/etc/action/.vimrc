set nocompatible 
set autoindent
set backspace=indent,eol,start
set display=truncate
set formatoptions+=j
set hlsearch        
set incsearch    
set ruler		
set ttyfast          
set showcmd		
set wildmenu		
set nrformats-=octal
set nolangremap
set viminfo=%,<10000,'128,/128,:128
set viminfofile=/root/.temp/.viminfo
set scrolloff=10
set smartindent
let g:is_posix = 1
try                   
    syntax on       
catch | endtry        
if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
    set fileencodings=ucs-bom,utf-8,latin1
endif
" CTRL-L will mute highlighted search results
nnoremap <silent> <C-l> :<C-u>nohlsearch<CR><C-l>
" F12 to comment/uncomment a visual selection block
autocmd FileType go,c,cpp,java,scala  let b:comment_leader = '//'
autocmd FileType sh,ruby,python,squid let b:comment_leader = '#'
function! CommentToggle()
    execute ':silent! s/^/' . escape(b:comment_leader,'\/') . ' \1/'
    execute ':silent! s/^\( *\)' . escape(b:comment_leader,'\/') . ' \?' . escape(b:comment_leader,'\/') . ' \?/\1/'
endfunction
map <F12> :call CommentToggle()<CR>
