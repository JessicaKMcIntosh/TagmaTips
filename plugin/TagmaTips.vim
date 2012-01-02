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

" Line limit for the body of a tool tip.
call s:SetDefault('g:TagmaTipsLineLimit',       30)

" No need for the function any longer.
delfunction s:SetDefault
" }}}1

" Settings for each supported file type. {{{1
"
" For each file type the following settings are present:
"   loaded  Boolean to indicate if file type specific settings are loaded.
"           Only present when the file type settings are loaded.
"           To disable checking for file type specific settings set this.
"   blank   Regexp that matches a 'blank' line.
"   proc    Regexp that matches a procedure definition.
"   prim    Dictionary of language primitives.
"   vars    Dictionary of language variables.
"   expr    If present this function is called if no matches are found for the
"           word under the cursor.
"   palias  Dictionary of primitive aliases.
"   valias  Dictionary of variable aliases.
"
" The alias keys 'palias' and 'valias' are used when a primitive or variable
" can have several names. If an alias matches then that word is looked up in
" the respective dictionary. For example the Perl documentation for the '-X'
" operator is would have aliases keys for '-r', '-w' and so on.
"
" The 'vars', 'prim', 'palias' and 'valias' dictionaries are populated from an
" autoload plugin for that file type.
"
" The 'proc' regexp must contain two groupings:
"   #1  The procedure definition for the tooltip.
"   #2  The name of the procedure for the dictionary of user procedures.
"
" They keys 'blank' and 'proc' are required. The others are optional or will
" be created during setup.
let g:TagmaTipsSettings = {
    \   'awk':  {
    \       'blank':    '^\}\?\s*$',
    \       'proc':     '^\s*func\w*\s\+\(\([^[:space:](]\+\)\(\s\+\|(\).\{-}\)\(\s\+{\s*\)\?$',
    \   },
    \   'perl':  {
    \       'blank':    '^\}\?\s*$',
    \       'proc':     '^\s*sub\s\+\(\(\w\+\)\s[^{]*\)',
    \   },
    \   'tcl':  {
    \       'blank':    '^\}\?\s*$',
    \       'proc':     '^\s*proc\s\+\(\%(::\w\+::\)*\(\S\+\)\s\+.\{-}\)\%(\s\+{\s*\)\?$',
    \   },
    \   'vim':  {
    \       'blank':    '^\s*$',
    \       'proc':     '^\s*\<fu\%[nction]!\=\s\+\(\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\=\(\%(\i\|[#.]\|{.\{-1,}}\)*\)\s*(.*).*\)',
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
    let g:TagmaTipsSettings[a:type]['prim'] = {}
    let g:TagmaTipsSettings[a:type]['vars'] = {}
    let g:TagmaTipsSettings[a:type]['palias'] = {}
    let g:TagmaTipsSettings[a:type]['valias'] = {}

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
