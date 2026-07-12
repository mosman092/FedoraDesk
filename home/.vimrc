" =============================================================================
"  ~/.vimrc — VS Code-style vim for FedoraDesk
" =============================================================================
"  Familiar editor keys layered ON TOP OF vim. Every normal-mode vim command
"  (hjkl, dd, yy, ciw, /, :, u, . …) still works — only a few keys are
"  reassigned to make room for the CUA / VS Code shortcuts:
"     Ctrl-V   paste             (blockwise-visual moves to  Ctrl-Q)
"     Ctrl-A   select all        (increment number stays on  g Ctrl-A)
"     Ctrl-X   cut               (decrement number stays on  g Ctrl-X)
"     Ctrl-Z   undo              (suspend vim with  :suspend  / :sh)
"     Ctrl-F   find (search /)   (page down stays on  PageDown / Ctrl-D)
"  Copy/paste go through wl-clipboard, so they sync with the Wayland clipboard
"  in foot whether or not this vim was built with +clipboard.
" =============================================================================

set nocompatible
filetype plugin indent on
syntax on

" ---- sensible defaults ------------------------------------------------------
set number                           " line numbers (absolute, like VS Code)
set cursorline                       " highlight the current line
set mouse=a                          " mouse: click / select / scroll / resize
set encoding=utf-8
set backspace=indent,eol,start
set hidden                           " switch buffers without saving
set autoread                         " pick up files changed on disk
set confirm                          " prompt to save instead of erroring out
set incsearch hlsearch               " search as you type, highlight matches
set ignorecase smartcase             " case-insensitive unless you Type Caps
set autoindent smartindent
set expandtab tabstop=4 shiftwidth=4 softtabstop=4   " 4 spaces per indent
set wrap linebreak                   " soft-wrap on word boundaries
set scrolloff=4 sidescrolloff=8
set laststatus=2 ruler showcmd wildmenu
set splitright splitbelow
set updatetime=300 timeoutlen=400
set title belloff=all
set keymodel=startsel,stopsel        " Shift+arrows start / extend a selection
set whichwrap+=<,>,[,]               " arrows wrap across line boundaries

" No swapfiles — avoids the 'swap already exists' prompt on quick edits (e.g. a
" config opened twice from the bar). Persistent undo keeps recovery instead.
set noswapfile undofile
let s:undodir = expand('~/.vim/undo')
if !isdirectory(s:undodir) | call mkdir(s:undodir, 'p', 0700) | endif
let &undodir = s:undodir

" per-filetype indent tweaks
augroup ft_indent
  autocmd!
  autocmd FileType html,css,scss,javascript,typescript,json,jsonc,yaml,lua,vim
        \ setlocal shiftwidth=2 tabstop=2 softtabstop=2
  autocmd FileType make setlocal noexpandtab
  autocmd FileType gitcommit setlocal spell textwidth=72
augroup END

" ---- system clipboard via wl-clipboard --------------------------------------
function! s:WlCopy(text) abort
  if executable('wl-copy') | call system('wl-copy', a:text) | endif
endfunction
function! s:WlPaste() abort
  if executable('wl-paste') | return system('wl-paste --no-newline') | endif
  return getreg('"')
endfunction
function! s:Paste() abort
  call setreg('"', s:WlPaste(), 'c')
  normal! gP
endfunction
" mirror every yank to the Wayland clipboard, so y / yy / yiw 'copy' too
if executable('wl-copy')
  augroup wl_yank
    autocmd!
    autocmd TextYankPost * call s:WlCopy(join(v:event.regcontents, "\n")
          \ . (v:event.regtype ==# 'V' ? "\n" : ''))
  augroup END
endif

" ---- VS Code / CUA keybindings ---------------------------------------------
" Save (normal / insert / visual)
nnoremap <C-s> :write<CR>
inoremap <C-s> <C-o>:write<CR>
xnoremap <C-s> <Esc>:write<CR>

" Undo / Redo
nnoremap <C-z> u
inoremap <C-z> <C-o>u
nnoremap <C-y> <C-r>
inoremap <C-y> <C-o><C-r>

" Select all
nnoremap <C-a> ggVG
inoremap <C-a> <Esc>ggVG

" Find (open search); double-Esc clears the match highlight
nnoremap <C-f> /
inoremap <C-f> <C-o>/
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Copy / Cut / Paste — clipboard handled by wl-clipboard
xnoremap <silent> <C-c> y:call <SID>WlCopy(getreg('0'))<CR>
nnoremap <silent> <C-c> yy:call <SID>WlCopy(getreg('0'))<CR>
xnoremap <silent> <C-x> d:call <SID>WlCopy(getreg('"'))<CR>
nnoremap <silent> <C-x> dd:call <SID>WlCopy(getreg('"'))<CR>
nnoremap <silent> <C-v> :call <SID>Paste()<CR>
xnoremap <silent> <C-v> "_d:call <SID>Paste()<CR>
inoremap <silent> <C-v> <C-r>=<SID>WlPaste()<CR>
cnoremap          <C-v> <C-r>=<SID>WlPaste()<CR>

" Blockwise-visual (old Ctrl-V) now lives on Ctrl-Q
nnoremap <C-q> <C-v>

" Indent / outdent while keeping the selection (Tab / Shift-Tab in visual)
xnoremap <Tab>   >gv
xnoremap <S-Tab> <gv

" Toggle line comment (Ctrl-/ — terminals send <C-_>)
function! s:Comment() range abort
  let l:cms = &commentstring !=# '' ? &commentstring : '# %s'
  let l:pre = substitute(matchstr(l:cms, '^.\{-}\ze%s'), '\s\+$', '', '')
  if l:pre ==# '' | let l:pre = '#' | endif
  let l:epre = '\V' . escape(l:pre, '\')
  for l:ln in range(a:firstline, a:lastline)
    let l:txt = getline(l:ln)
    if l:txt =~# '^\s*$' | continue | endif
    if l:txt =~# '^\s*' . l:epre
      call setline(l:ln, substitute(l:txt, '^\(\s*\)' . l:epre . '\s\?', '\1', ''))
    else
      call setline(l:ln, substitute(l:txt, '^\(\s*\)', '\1' . l:pre . ' ', ''))
    endif
  endfor
endfunction
nnoremap <silent> <C-_> :call <SID>Comment()<CR>
xnoremap <silent> <C-_> :call <SID>Comment()<CR>gv

" ---- colors -----------------------------------------------------------------
set background=dark                  " inherit the foot terminal palette
