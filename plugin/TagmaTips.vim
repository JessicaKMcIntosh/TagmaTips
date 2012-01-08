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

" s:CheckCacheDir -- Check the cache directory. {{{1
"   The directory is created if it does not exist.
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side effect:
"   Creates the cache directory if it does not exist.
function! s:CheckCacheDir()
    " Make sure the path ends in a slash.
    if g:TagmaTipsCachePath !~ '[/\\]$'
        let g:TagmaTipsCachePath .= '/'
    endif

    " Make sure the directory exists.
    if !isdirectory(g:TagmaTipsCachePath)
        if !exists("*mkdir") 
            echoerr "Unable to create the TagmaTips cache directory '" .
                        \ g:TagmaTipsCachePath . "'"
            let g:TagmaTipsEnableCache = 0
        elseif !mkdir(g:TagmaTipsCachePath)
            echoerr "Error creating the TagmaTips cache directory '" .
                        \ g:TagmaTipsCachePath . "'"
            let g:TagmaTipsEnableCache = 0
        else
            echomsg "Created the TagmaTips cache directory '" .
                        \ g:TagmaTipsCachePath . "'"
        endif
    endif
endfunction " }}}1

" Defaults {{{1
function! s:SetDefault(option, default)
    if !exists(a:option)
        execute 'let ' . a:option . '=' . string(a:default)
    endif
endfunction

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
if g:TagmaTipsEnableCache
    call s:CheckCacheDir()
endif

" No need for the function any longer.
delfunction s:SetDefault
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

" s:SetupType -- Setup a tool tip type. {{{1
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
"   Updates g:TagmaTipsSettings with additional settings.
"   Create an auto command for each the file type.
function! s:SetupType(type)
    " Create additional settings for the file type.
    let g:TagmaTipsSettings[a:type]['_prim'] = {}
    let g:TagmaTipsSettings[a:type]['_vars'] = {}
    let g:TagmaTipsSettings[a:type]['_palias'] = {}
    let g:TagmaTipsSettings[a:type]['_valias'] = {}

    " Create the autocommand for the file type.
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
"   Performs additional setup for each file type.
function! s:SetupTips()
    " Allow the user to only enable certain types.
    if exists("g:TagmaTipsTypes") && type(g:TagmaTipsTypes) == 3
        " Enable only the requested types.
        for l:type in g:TagmaTipsTypes
            if has_key(g:TagmaTipsSettings, l:type)
                call s:SetupType(l:type)
            endif
        endfor
    else
        " Enable all types.
        for l:type in keys(g:TagmaTipsSettings)
            call s:SetupType(l:type)
        endfor
    endif
endfunction " }}}1

" Setup Tagma Tool Tips.
call s:SetupTips()

" Restore the saved compatibility options.
let &cpo = s:cpo_save
unlet s:cpo_save
