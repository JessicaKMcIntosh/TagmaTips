" Tagma Tool Tips/Balloon Plugin
" File:         TagmaTips.vim
" Last Changed: 2011-09-10
" Maintainer:   Lorance Stinson @ Gmail ...
" Version:      0.1
" Home:         https://github.com/LStinson/TagmaTips
" License:      Public Domain
"
" Install:      Place the files in ~/.vim or ~/vimfiles
"               If using a manager (like Pathogen) place in
"               ~/.vim/bundle or ~/vimfiles/bundle
"
" Description:
" Displays a tooltip when the cursor hovers over certain words.
" See :help balloon for details.

" Only process the plugin once.
if exists("g:loadedTagmaTips") || &cp || !has('balloon_eval')
    finish
endif
let g:loadedTagmaTips= 1

" Setup the balloon options for the current buffer.
function! TagmaTipsSet()
    if !exists("b:loadedTagmaTipsBuffer")
        " Check that the file type is supported.
        let l:file_type = &ft
        if !has_key(s:TagmaTipsSupported, l:file_type) ||
            \ s:TagmaTipsSupported[l:file_type] == 0
            return
        endif

        " Setup the Tool Tips for this buffer.
        if l:file_type == "awk"
            call TagmaTipsAwk#Setup()
        elseif l:file_type == "tcl"
            call TagmaTipsTcl#Setup()
        endif
    endif
endfunction

" Setup the toolTips and auto command.
function! TagmaTipsSetup()
    " Allow the user to only enable certain types.
    if exists("g:TagmaTipsTypes") && type(g:TagmaTipsTypes) == 3
        for type in g:TagmaTipsTypes
            let s:TagmaTipsSupported[type] = 1
        endfor
    else
        for type in keys(s:TagmaTipsSupported)
            let s:TagmaTipsSupported[type] = 1
        endfor
    endif
    " Check every file and try to setup the Tool Tips.
    au BufReadPost,BufNewFile,FileType * call TagmaTipsSet()
endfunction

" Supported file system types.
let s:TagmaTipsSupported = {
    \ 'tcl':    0,
    \ 'awk':    0,
    \ }

" Setup Tagma Tool Tips.
call TagmaTipsSetup()
