" Tagma Tool Tips settings for Vim.
" vim:foldmethod=marker
" File:         autoload/TagmaTipsvim.vim
" Last Changed: Sun, Jan 1, 2012
" Maintainer:   Lorance Stinson @ Gmail ...
" Home:         https://github.com/LStinson/TagmaTips
" License:      Public Domain
"
" Description:
" Vim specific settings for the Tagma Tool Tips Plugin

" Make sure the continuation lines below do not cause problems in
" compatibility mode.
let s:cpo_save = &cpo
set cpo-=C

" Autoload Functions:

" TagmaTipsvim#LoadSettings -- Load the Vim Settings. {{{1
"   Loads the Vim specific settings into g:TagmaTipsSettings.
"   Load variable and function definitions from the eval.txt help file.
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side Effects:
"   Updates g:TagmaTipsSettings.
"   Sets '_expr' to 'TagmaTipsvim#TipsExpr()' for finding tool tips.
"   Sets 'ivars' to a list of internal variables from 'eval.txt'.
"   Sets 'builtin' to a list of builtin functions from 'eval.txt'.
"   Sets 'feature' to a list of features from 'eval.txt'.
"
"   Caches the data to a file for faster reload later.
"   If the cache file is present loads the data from the file.
function! TagmaTipsvim#LoadSettings()
    " Check to see if this feature has been disabled.
    if g:TagmaTipsVimDisable 
        return 0
    endif

    " Internal variables, builtin functions and features.
    let g:TagmaTipsSettings['vim']['builtin'] = {}
    let g:TagmaTipsSettings['vim']['ealias']  = {}
    let g:TagmaTipsSettings['vim']['event']   = {}
    let g:TagmaTipsSettings['vim']['feature'] = {}
    let g:TagmaTipsSettings['vim']['ivars']   = {}
    let g:TagmaTipsSettings['vim']['oalias']  = {}
    let g:TagmaTipsSettings['vim']['option']  = {}

    " Vim tool tips function.
    let g:TagmaTipsSettings['vim']['_expr'] = 'TagmaTipsvim#TipsExpr()'

    " Attempt to load the tool tip data from the cache file.
    if g:TagmaTipsEnableCache && TagmaTips#CacheLoad('vim')
        return 1
    endif

    " Load tool tip data from autocmd.txt.
    let l:help_file = fnamemodify(&helpfile, ':h') . '/autocmd.txt'
    if filereadable(l:help_file)
        call s:LoadAutocmd(l:help_file)
    endif

    " Load tool tip data from eval.txt.
    let l:help_file = fnamemodify(&helpfile, ':h') . '/eval.txt'
    if filereadable(l:help_file)
        call s:LoadEval(l:help_file)
    endif

    " Load tool tip data from options.txt.
    let l:help_file = fnamemodify(&helpfile, ':h') . '/options.txt'
    if filereadable(l:help_file)
        call s:LoadOptions(l:help_file)
    endif

    " Cache the data for faster load next time.
    if g:TagmaTipsEnableCache
        call TagmaTips#CacheSave('vim',
                    \ ["builtin", "ealias", "event", "feature",
                    \  "ivars", "oalias", "option"])
    endif
endfunction " }}}1

" TagmaTipsvim#TipsExpr() -- Vim tool tip lookup function. {{{1
"   Called if the normal TipsExpr() can not find a tool tip for the line.
"
" Arguments:
"   None
"
" Result:
"   Tool tip for the word under the cursor.
"
" Side Effects:
"   None
function! TagmaTipsvim#TipsExpr()
    " Get the line the cursor is over.
    let l:tip_line = getbufline(v:beval_bufnr, v:beval_lnum, v:beval_lnum)[0]

    " See if the cursor is over a function.
    if strpart(l:tip_line, v:beval_col) =~ '^\w*\s*(' &&
            \ has_key(g:TagmaTipsSettings['vim']['builtin'], v:beval_text)
        return g:TagmaTipsSettings['vim']['builtin'][v:beval_text]
    endif

    " First part of the line to the cursor position.
    let l:line_start = strpart(l:tip_line, 0, v:beval_col)

    " See if the cursor is over an internal variable definition.
    if l:line_start =~ 'v:\w\+$' &&
            \ has_key(g:TagmaTipsSettings['vim']['ivars'], v:beval_text)
        return g:TagmaTipsSettings['vim']['ivars'][v:beval_text]
    endif

    " See if the cursor is over a feature.
    if l:line_start =~ 'has\s*(.\w\+$' &&
            \ has_key(g:TagmaTipsSettings['vim']['feature'], v:beval_text)
        return g:TagmaTipsSettings['vim']['feature'][v:beval_text]
    endif

    " See if the cursor is over an option.
    if l:line_start =~ '&\%([lg]:\)\?\w\+$' || l:line_start =~ 'set\s\+\w\+$'
        if has_key(g:TagmaTipsSettings['vim']['option'], v:beval_text)
            return g:TagmaTipsSettings['vim']['option'][v:beval_text]
        endif
        if has_key(g:TagmaTipsSettings['vim']['oalias'], v:beval_text)
            return g:TagmaTipsSettings['vim']['option'][
                        \ g:TagmaTipsSettings['vim']['oalias'][v:beval_text]]
        endif
    endif

    " See if the cursor is over an autocmd.
    if l:line_start =~ 'au\w*\s\+\%(\w\+\s\+\)\?'
        if has_key(g:TagmaTipsSettings['vim']['event'], v:beval_text)
            return g:TagmaTipsSettings['vim']['event'][v:beval_text]
        endif
        if has_key(g:TagmaTipsSettings['vim']['ealias'], v:beval_text)
            return g:TagmaTipsSettings['vim']['event'][
                        \ g:TagmaTipsSettings['vim']['ealias'][v:beval_text]]
        endif
    endif

    " Default to nothing.
    " This will cause TipsExpr() to check spelling as a last resort.
    return []
endfunction " }}}1

" Utility Functions:

" s:LoadAutocmd -- Load tool tip data from autocmd.txt. {{{1
"   Reads tool tip data from the 'autocmd.txt' help file.
"
" Arguments:
"   help_file   The full path to autocmd.txt.
"
" Result:
"   None
"
" Side Effects:
"   Sets 'event' to a list of autocmd events.
"   Sets 'ealias' to a list of autocmd event aliases.
function! s:LoadAutocmd(help_file)
    " Read the file looking for autocmd events.
    let l:section = 0           " The current section.
    let l:name = ''             " The name of the tool tip item.
    let l:body = []             " The body of the tool tip item.
    for l:line in readfile(a:help_file)
        if l:line =~ '^The alphabetical list of autocommand events:'
            let l:section = 1
        elseif l:section && l:line =~ '^=\+$'
            return
        elseif l:section == 0
            " Do nothing...
        elseif l:name != '' && (l:line == '' || l:line =~ '^\s\+\*')
            call TagmaTips#StoreTip('vim', 'event', l:name, l:body)
            let l:name = ''
        elseif l:line =~ '^\w\+'
            let l:matches = matchlist(l:line, '^\(\(\w\+\)\%(\s\+or\s\+\(\w\+\)\)\?\)\s\+\(.*\)$')
            if len(l:matches) != 0
                let l:name = l:matches[2]
                if l:matches[3] != ''
                    let g:TagmaTipsSettings['vim']['ealias'][l:matches[3]] = l:name
                endif
                let l:line = substitute(l:matches[4], '\t', '        ', 'g')
                let l:body = [l:matches[1], '', l:line]
            endif
        elseif l:name != '' && l:line != '' && l:line !~ '^\s\+\*'
            " Have a name so collect the body of a definition.
            let l:line = substitute(l:line, '^\(<\?\)\t\+', '', '')
            call add(l:body, substitute(l:line, '\t', '        ', 'g'))
        endif
    endfor
endfunction " }}}1

" s:LoadEval -- Load tool tip data from eval.txt. {{{1
"   Reads tool tip data from the 'eval.txt' help file.
"
" Arguments:
"   help_file   The full path to eval.txt.
"
" Result:
"   None
"
" Side Effects:
"   Sets 'ivars' to a list of internal variables from 'eval.txt'.
"   Sets 'builtin' to a list of builtin functions from 'eval.txt'.
"   Sets 'feature' to a list of features from 'eval.txt'.
function! s:LoadEval(help_file)
    " Read the file looking for internal variable, builtin function
    " definitions and features.
    let l:section = 0           " The current section.
    let l:buried_func = 0       " Buried function definition.
    let l:name = ''             " The name of the tool tip item.
    let l:body = []             " The body of the tool tip item.
    for l:line in readfile(a:help_file)
        if l:line =~ '^Predefined Vim variables:'
            " Start of the variables.
            let l:section = 1
        elseif l:line =~ '^\d\+\.\s\+Builtin Functions\s\+\*\w\+\*'
            " Start of the functions.
            let l:section = 2
        elseif l:line =~ '^=\+$'
            " End of a section.
            let l:section = 0
        elseif l:section == 1
            " Process internal variables.
            if l:name != '' && l:line == ''
                call TagmaTips#StoreTip('vim', 'ivars', l:name, l:body)
                let l:name = ''
            elseif l:line =~ '^v:\w\+\s'
                let l:matches = matchlist(l:line, '^v:\(\w\+\)\s\+\(.*\)$')
                if len(l:matches) != 0
                    let l:name = l:matches[1]
                    let l:body = [l:matches[1], '', l:matches[2]]
                endif
            elseif l:name != '' && l:line != ''
                " Have a name so collect the body of a definition.
                call add(l:body, substitute(l:line, '^\(<\?\)\t\t', '', ''))
            endif
        elseif l:section == 2
            " Process builtin function definitions.
            if l:line =~ '^\s*\*feature-list\*\s*$'
                call TagmaTips#StoreTip('vim', 'builtin', l:name, l:body)
                let l:section = 3
            elseif l:line =~ '^\w\+([^)]*)\%(\s\+\*[^*]\+\*\)*\s*$'
                let l:matches = matchlist(l:line, '\(\(\w\+\)([^)]*)\)')
                if len(l:matches) != 0
                    call TagmaTips#StoreTip('vim', 'builtin', l:name, l:body)
                    let l:name = l:matches[2]
                    let l:body = [l:matches[1], '']
                endif
            elseif l:line =~ '^\s\+\%(\*[^*]\+\*\s*\)\+$'
                let l:buried_func = 1
            elseif l:buried_func
                let l:buried_func = 0
                let l:matches = matchlist(l:line, '^\(\(\w\+\)([^)]*)\)\s\+\(.*\)$')
                if len(l:matches) != 0
                    call TagmaTips#StoreTip('vim', 'builtin', l:name, l:body)
                    let l:name = l:matches[2]
                    let l:body = [l:matches[1], '', l:matches[3]]
                endif
            elseif l:name != '' && l:line !~ '^\s*<\s*$'
                " Have a name so collect the body of a definition.
                let l:line = substitute(l:line, '^\(<\?\)\t\t', '', '')
                call add(l:body, substitute(l:line, '\t', '        ', 'g'))
            endif
        elseif l:section == 3
            " Process features.
            if l:line =~ '^\s*\*string-match\*\s*$'
                call TagmaTips#StoreTip('vim', 'feature', l:name, l:body)
                let l:section = 0
                break
            elseif l:line =~ '^\w\+\t'
                let l:matches = matchlist(l:line, '^\(\w\+\)\t\+\(.*\)$')
                if len(l:matches) != 0
                    call TagmaTips#StoreTip('vim', 'feature', l:name, l:body)
                    let l:name = l:matches[1]
                    let l:body = [l:matches[1], '', l:matches[2]]
                endif
            elseif l:name != '' && l:line != ''
                " Have a name so collect the body of a definition.
                call add(l:body, substitute(l:line, '^\s\+', '', ''))
            endif
        endif
    endfor
endfunction " }}}1

" s:LoadOptions -- Load tool tip data from options.txt. {{{1
"   Reads tool tip data from the 'options.txt' help file.
"
" Arguments:
"   help_file   The full path to options.txt.
"
" Result:
"   None
"
" Side Effects:
"   Sets 'option' to a list of options variables from 'options.txt'.
"   Sets 'oalias' to a list of option aliases.
function! s:LoadOptions(help_file)
    " Read the file looking for internal variable, builtin function
    " definitions and features.
    let l:section = 0           " The current section.
    let l:name = ''             " The name of the tool tip item.
    let l:body = []             " The body of the tool tip item.
    for l:line in readfile(a:help_file)
        if l:line =~ '^\d\+\.\s\+Options summary\s\+\*[^*]\+\*\s*$'
            let l:section = 1
        elseif l:section == 0
            " Do nothing...
        elseif l:name != '' && l:line == ''
            call TagmaTips#StoreTip('vim', 'option', l:name, l:body)
            let l:name = ''
        elseif l:line =~ '^''\w\+''\%(\s\+''\w\+''\)\?\t'
            let l:matches = matchlist(l:line, '^''\(\w\+\)''\%(\s\+''\(\w\+\)''\)\?\t')
            if len(l:matches) != 0
                let l:name = l:matches[1]
                if l:matches[2] != ''
                    let g:TagmaTipsSettings['vim']['oalias'][l:matches[2]] = l:name
                endif
                let g:TagmaTipsSettings['vim']['oalias']['no' . l:name] = l:name
                let l:line = substitute(l:line, '\t', '        ', 'g')
                let l:body = [l:line]
            endif
        elseif l:name != '' && l:line != ''
            " Have a name so collect the body of a definition.
            let l:line = substitute(l:line, '^\(<\?\)\t\t', '', '')
            call add(l:body, substitute(l:line, '\t', '        ', 'g'))
        endif
    endfor
endfunction " }}}1

" Restore the saved compatibility options.
let &cpo = s:cpo_save
unlet s:cpo_save
