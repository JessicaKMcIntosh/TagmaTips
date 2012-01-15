" Tagma Tool Tips/Balloon Plugin
" vim:foldmethod=marker
" File:         plugin/TagmaTips.vim
" Last Changed: Sun, Jan 1, 2012
" Maintainer:   Lorance Stinson @ Gmail ...
" Home:         https://github.com/LStinson/TagmaTips
" License:      Public Domain
"
" Install:      Place the files in ~/.vim or ~/vimfiles
"               If using a manager (like Pathogen) place in
"               ~/.vim/bundle or ~/vimfiles/bundle
"
" Description:
" Displays a tooltip when the cursor hovers over certain words.
" See :help TagmaTips for more information on using this plugin.
" See :help balloon for details on how tool tips work.

" Make sure the continuation lines below do not cause problems in
" compatibility mode.
let s:cpo_save = &cpo
set cpo-=C

" Only process the plugin once. {{{1
if exists("g:loadedTagmaTips") || &cp || !has('balloon_eval') || !has('gui_running')
    finish
endif
let g:loadedTagmaTips= 1
" }}}1

" Defaults {{{1
function! s:SetDefault(option, default)
    if !exists(a:option)
        execute 'let ' . a:option . '=' . string(a:default)
    endif
endfunction

" Auto enable.
call s:SetDefault('g:TagmaTipsAutoEnable',      1)

" Enable debugging.
call s:SetDefault('g:TagmaTipsDebugMode',       0)

" Enable caching, if the file type supports it.
call s:SetDefault('g:TagmaTipsEnableCache',     1)

" Enable the enhanced Vim features.
call s:SetDefault('g:TagmaTipsVimDisable',      0)

" Line limit for the body of a tool tip.
call s:SetDefault('g:TagmaTipsLineLimit',       30)

" The path to the cache directory.
call s:SetDefault('g:TagmaTipsCachePath',       expand('<sfile>:p:h:h') . '/cache/')

" No need for the function any longer.
delfunction s:SetDefault
" }}}1

" User Commands {{{1

" Close the Buffer Manager.
command! -nargs=0 EnableTips        call s:EnableTagmaTips()
" }}}1

" Settings for each supported file type. {{{1
" See :help TagmaTips-api for details of these settings.
let g:TagmaTipsSettings = {
    \   'awk':  {
    \       '_blank':    '^\}\?\s*$',
    \       '_proc':     '^\s*func\w*\s\+\(\([^[:space:](]\+\)\(\s\+\|(\).\{-}\)\(\s\+{\s*\)\?$',
    \   },
    \   'perl':  {
    \       '_blank':    '^\}\?\s*$',
    \       '_proc':     '^\s*sub\s\+\(\(\w\+\)\s[^{]*\)',
    \   },
    \   'tcl':  {
    \       '_blank':    '^\}\?\s*$',
    \       '_proc':     '^\s*proc\s\+\(\%(::\w\+::\)*\(\S\+\)\s\+.\{-}\)\%(\s\+{\s*\)\?$',
    \   },
    \   'vim':  {
    \       '_blank':    '^\s*$',
    \       '_proc':     '^\s*\<fu\%[nction]!\=\s\+\(\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\=\(\%(\i\|[#.]\|{.\{-1,}}\)*\)\s*(.*).*\)',
    \   },
    \ } " }}}1

" s:EnableTagmaTips -- Enable Tool Tips for the current buffer. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side effect:
"   Prints an error if tool tips are not available for the current file type.
"   Prints an error if tool tips are already setup for the current buffer.
"   Tool Tips are setup for the current buffer.
"   A message is printed that tool tips are enabled.
function! s:EnableTagmaTips()
    " Make sure the file type is supported.
    if !has_key(g:TagmaTipsSettings, &filetype)
        echoerr 'Tool Tips are not supported for the current file type.'
        return 0
    endif

    " Make sure tool tips are not already enabled for the current buffer.
    if exists('b:TagmaToolTipsProcs')
        echoerr 'Tool Tips are already enabled for the current buffer.'
        return 0
    endif

    " Enable Tool Tips.
    call TagmaTips#SetupBuffer()
    echomsg "Tool Tips have been enabled for the current buffer."
endfunction " }}}1

" s:SetupAutocmd -- Setup a tool tip autocmd. {{{1
"   Configures additional settgins for the type.
"   Creates the autocmd for the type.
"
" Arguments:
"   type        The file typ to setup.
"
" Result:
"   None
"
" Side effect:
"   Create an auto command for each the file type.
function! s:SetupAutocmd(type)
    execute 'autocmd FileType ' . a:type . ' call TagmaTips#SetupBuffer()'
endfunction " }}}1

" s:SetupTips -- Setup the tool tips for the supported file types. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side effect:
"   Created autocommands for each enabled/supported file type.
function! s:SetupTips()
    " Allow the user to only enable certain types.
    if exists("g:TagmaTipsTypes") && type(g:TagmaTipsTypes) == 3
        " Enable only the requested types.
        for l:type in g:TagmaTipsTypes
            if has_key(g:TagmaTipsSettings, l:type)
                call s:SetupAutocmd(l:type)
            endif
        endfor
    else
        " Enable all types.
        for l:type in keys(g:TagmaTipsSettings)
            call s:SetupAutocmd(l:type)
        endfor
    endif
endfunction " }}}1

" Setup Tagma Tool Tips if automatically enabled.
if g:TagmaTipsAutoEnable
    call s:SetupTips()
endif

" Restore the saved compatibility options.
let &cpo = s:cpo_save
unlet s:cpo_save
