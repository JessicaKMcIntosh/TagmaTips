" Tagma Tool Tips settings for Vim.
" vim:foldmethod=marker
" File:         autoload/TagmaTipsvim.vim
" Last Changed: Sat, Dec 31, 2011
" Maintainer:   Lorance Stinson @ Gmail ...
" Home:         https://github.com/LStinson/TagmaTips
" License:      Public Domain
"
" Description:
" Vim specific settings for the Tagma Tool Tips Plugin

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
" Side effect:
"   Updates g:TagmaTipsSettings.
"   Sets 'expr' to 'TagmaTipsvim#TipsExpr()' for finding tool tips.
"   Sets 'ivars' to a list of internal variables from 'eval.txt'.
"   Sets 'prim' to a list of builtin functions from 'eval.txt'.
function! TagmaTipsvim#LoadSettings()
    " Vim tool tips function.
    let g:TagmaTipsSettings['vim']['expr'] = 'TagmaTipsvim#TipsExpr()'

    " Internal variables.
    let g:TagmaTipsSettings['vim']['ivars'] = {}

    " See if the 'eval.txt' help file is readable.
    let l:eval_file = fnamemodify(&helpfile, ':h') . '/eval.txt'
    if !filereadable(l:eval_file)
        return 0
    endif

    " Read the file looking for internal variable and builtin function
    " definitions.
    let l:found_vars = 0
    let l:found_funcs = 0
    let l:burried_func = 0
    let l:name = ''
    let l:body = []
    for l:line in readfile(l:eval_file)
        if l:line =~ '^Predefined Vim variables:'
            " Start of the variables.
            let l:found_vars = 1
        elseif l:line =~ '^\d\+\.\s\+Builtin Functions\s\+\*\w\+\*'
            " Start of the functions.
            let l:found_funcs = 1
        elseif l:line =~ '^=\+$'
            " End of a section.
            let l:found_vars = 0
            let l:found_funcs = 0
        elseif l:found_vars
            if l:name != '' && l:line == ''
                call s:StashToolTip('ivars', l:name, l:body)
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
        elseif l:found_funcs
            " Proces builtin function definitions.
            if l:line =~ '^\s*\*feature-list\*\s*$'
                call s:StashToolTip('prim', l:name, l:body)
                let l:found_funcs = 0
            elseif l:line =~ '^\w\+([^)]*)\%(\s\+\*[^*]\+\*\)*\s*$'
                let l:matches = matchlist(l:line, '\(\(\w\+\)([^)]*)\)')
                if len(l:matches) != 0
                    call s:StashToolTip('prim', l:name, l:body)
                    let l:name = l:matches[2]
                    let l:body = [l:matches[1], '']
                endif
            elseif l:line =~ '^\s\+\%(\*[^*]\+\*\s*\)\+$'
                let l:burried_func = 1
            elseif l:burried_func
                let l:burried_func = 0
                let l:matches = matchlist(l:line, '^\(\(\w\+\)([^)]*)\)\s\+\(.*\)$')
                if len(l:matches) != 0
                    call s:StashToolTip('prim', l:name, l:body)
                    let l:name = l:matches[2]
                    let l:body = [l:matches[1], '', l:matches[3]]
                endif
            elseif l:name != ''
                " Have a name so collect the body of a definition.
                call add(l:body, substitute(l:line, '^\(<\?\)\t\t', '', ''))
            endif
        endif
    endfor
endfunction

" s:StashToolTip -- Stash a tool tip into g:TagmaTipsSettings {{{1
"
" Arguments:
"   key         The key to stash into.
"   name        The name of the tip.
"   body        The tip body.
"
" Result:
"   None
"
" Side effect:
"   The tool tip is stored in g:TagmaTipsSettings.
function! s:StashToolTip(key, name, body)
    if a:name != ''
        let g:TagmaTipsSettings['vim'][a:key][a:name] = a:body
        "echoerr a:name
        "echoerr string(a:body)
    endif
endfunction

" TagmaTipsvim#TipsExpr() -- Vim tool tips function. {{{1
"
" Arguments:
"   None
"
" Result:
"   Tool tip for the word under the cursor.
"   This is called if the normal TipsExpr() can not find a tool tip for the
"   line.
"
" Side effect:
"   None
function! TagmaTipsvim#TipsExpr()
    " Get the line the cursor is over.
    let l:tip_line = getbufline(v:beval_bufnr, v:beval_lnum, v:beval_lnum)[0]

    " See if the cursor is over an internal veriable definition.
    if strpart(l:tip_line, 0, v:beval_col) =~ 'v:\a\+$' &&
            \ has_key(g:TagmaTipsSettings['vim']['ivars'], v:beval_text)
        return g:TagmaTipsSettings['vim']['ivars'][v:beval_text]
    endif

    " Default to nothing.
    " This will cause TipsExpr() to check spelling as a last resort.
    return []
endfunction
