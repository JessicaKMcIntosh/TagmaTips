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

" Only process the plugin once. {{{1
if exists("g:loadedTagmaTips") || &cp || !has('balloon_eval')
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

" Enable caching, if the file type supports it.
call s:SetDefault('g:TagmaTipsEnableCache',     1)

" Enable the enhanced Vim features.
call s:SetDefault('g:TagmaTipsVimDisable',      0)

" No need for the function any longer.
delfunction s:SetDefault
" }}}1

" Settings for each supported file type. {{{1
" For each file type the following settings are present:
"   loaded  Boolean to indicate if file type specific settings are loaded.
"           Only set when the file type settings are loaded.
"   blank   Regexp that matches a 'blank' line.
"   proc    Regexp that matches a procedure definition.
"   prim    Dictionary of language primitives.
"   vars    Dictionary of language variables.
"   expr    If present this function is called if no matches are found for the
"           word under the cursor.
"
" The 'vars' and 'prim' dictionaries are populated from an autoload plugin for
" that file type.
"
" The 'proc' regexp must contain two groupings:
"   #1  The procedure definition for the tooltip.
"   #2  The name of the procedure for the dictionary of user procedures.
let g:TagmaTipsSettings = {
    \   'awk':  {
    \       'blank':    '^\s*$',
    \       'proc':     '^\s*func\w*\s\+\(\([^[:space:](]\+\)\(\s\+\|(\).\{-}\)\(\s\+{\s*\)\?$',
    \       'prim':     {},
    \       'vars':     {},
    \   },
    \   'tcl':  {
    \       'blank':    '^\}\?\s*$',
    \       'proc':     '^\s*proc\s\+\(\%(::\w\+::\)*\(\S\+\)\s\+.\{-}\)\(\s\+{\s*\)\?$',
    \       'prim':     {},
    \       'vars':     {},
    \   },
    \   'vim':  {
    \       'blank':    '^\s*$',
    \       'proc':     '\<fu\%[nction]!\=\s\+\(\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\=\(\%(\i\|[#.]\|{.\{-1,}}\)*\)\s*(.*).*\)',
    \       'prim':     {},
    \       'vars':     {},
    \   },
    \ } " }}}1

" TagmaTipsAutocmd -- Create the autocommand for a file type. {{{1
"
" Arguments:
"   type        The file typ to create the autocommand for.
"
" Result:
"   None
"
" Side effect:
"   Create an auto command for each enabled type.
function! TagmaTipsAutocmd(type)
    execute 'au FileType ' . a:type . ' call TagmaTips#SetupBuffer()'
endfunction " }}}1

" TagmaTipsSetup -- Setup the supported file types and auto commands. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side effect:
"   Create an auto command for each enabled type.
function! TagmaTipsSetup()
    " Allow the user to only enable certain types.
    if exists("g:TagmaTipsTypes") && type(g:TagmaTipsTypes) == 3
        " Enable only the requested types.
        for l:type in g:TagmaTipsTypes
            if has_key(g:TagmaTipsSettings, l:type)
                call TagmaTipsAutocmd(l:type)
            endif
        endfor
    else
        " Enable all types.
        for l:type in keys(g:TagmaTipsSettings)
            call TagmaTipsAutocmd(l:type)
        endfor
    endif
endfunction " }}}1

" Setup Tagma Tool Tips.
call TagmaTipsSetup()
