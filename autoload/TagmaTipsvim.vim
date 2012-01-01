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
"   Sets 'builtin' to a list of builtin functions from 'eval.txt'.
"   Sets 'feature' to a list of features from 'eval.txt'.
function! TagmaTipsvim#LoadSettings()
    " Check to see if this has been disabled.
    if exists('g:TagmaTipsVimDisable') && g:TagmaTipsVimDisable 
        return
    endif

    " See if the 'eval.txt' help file is readable.
    let l:eval_file = fnamemodify(&helpfile, ':h') . '/eval.txt'
    if !filereadable(l:eval_file)
        return 0
    endif

    " Vim tool tips function.
    let g:TagmaTipsSettings['vim']['expr'] = 'TagmaTipsvim#TipsExpr()'

    " Internal variables, builtin functions and features.
    let g:TagmaTipsSettings['vim']['ivars'] = {}
    let g:TagmaTipsSettings['vim']['builtin'] = {}
    let g:TagmaTipsSettings['vim']['feature'] = {}

    " Read the file looking for internal variable, builtin function
    " definitions and features.
    let l:section = 0           " The current section.
    let l:buried_func = 0       " Buried function definition.
    let l:name = ''             " The name of the tool tip item.
    let l:body = []             " The body of the tool tip item.
    for l:line in readfile(l:eval_file)
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
        elseif l:section == 2
            " Process builtin function definitions.
            if l:line =~ '^\s*\*feature-list\*\s*$'
                call s:StashToolTip('builtin', l:name, l:body)
                let l:section = 3
            elseif l:line =~ '^\w\+([^)]*)\%(\s\+\*[^*]\+\*\)*\s*$'
                let l:matches = matchlist(l:line, '\(\(\w\+\)([^)]*)\)')
                if len(l:matches) != 0
                    call s:StashToolTip('builtin', l:name, l:body)
                    let l:name = l:matches[2]
                    let l:body = [l:matches[1], '']
                endif
            elseif l:line =~ '^\s\+\%(\*[^*]\+\*\s*\)\+$'
                let l:buried_func = 1
            elseif l:buried_func
                let l:buried_func = 0
                let l:matches = matchlist(l:line, '^\(\(\w\+\)([^)]*)\)\s\+\(.*\)$')
                if len(l:matches) != 0
                    call s:StashToolTip('builtin', l:name, l:body)
                    let l:name = l:matches[2]
                    let l:body = [l:matches[1], '', l:matches[3]]
                endif
            elseif l:name != '' && l:line !~ '^\s*<\s*$'
                " Have a name so collect the body of a definition.
                let l:line = substitute(l:line, '^\(<\?\)\t\t', '', '')
                let l:line = substitute(l:line, '\t', '        ', 'g')
                call add(l:body, l:line)
            endif
        elseif l:section == 3
            " Process features.
            if l:line =~ '^\s*\*string-match\*\s*$'
                call s:StashToolTip('feature', l:name, l:body)
                let l:section = 0
                break
            elseif l:line =~ '^\w\+\t'
                let l:matches = matchlist(l:line, '^\(\w\+\)\t\+\(.*\)$')
                if len(l:matches) != 0
                    call s:StashToolTip('feature', l:name, l:body)
                    let l:name = l:matches[1]
                    let l:body = [l:matches[1], '', l:matches[2]]
                endif
            elseif l:name != '' && l:line != ''
                " Have a name so collect the body of a definition.
                call add(l:body, substitute(l:line, '^\s\+', '', ''))
            endif
        endif
    endfor
endfunction

" s:StashToolTip -- Stash a tool tip into g:TagmaTipsSettings {{{1
"   Truncates the tool tip body to 30 rows.
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
        let l:body = a:body
        if len(l:body) > 30
            let l:body = l:body[0:30]
            call extend(l:body, ['', '...'])
        endif
        let g:TagmaTipsSettings['vim'][a:key][a:name] = l:body
    endif
endfunction

" TagmaTipsvim#TipsExpr() -- Vim tool tip lookup function. {{{1
"   Called if the normal TipsExpr() can not find a tool tip for the line.
"
" Arguments:
"   None
"
" Result:
"   Tool tip for the word under the cursor.
"
" Side effect:
"   None
function! TagmaTipsvim#TipsExpr()
    " Get the line the cursor is over.
    let l:tip_line = getbufline(v:beval_bufnr, v:beval_lnum, v:beval_lnum)[0]

    " See if the cursor is over a function.
    if strpart(l:tip_line, v:beval_col) =~ '\w\+\s*(' &&
            \ has_key(g:TagmaTipsSettings['vim']['builtin'], v:beval_text)
        return g:TagmaTipsSettings['vim']['builtin'][v:beval_text]
    endif

    " Last part of the line from the cursor position.
    let l:line_end = strpart(l:tip_line, 0, v:beval_col)

    " See if the cursor is over an internal variable definition.
    if l:line_end =~ 'v:\w\+$' &&
            \ has_key(g:TagmaTipsSettings['vim']['ivars'], v:beval_text)
        return g:TagmaTipsSettings['vim']['ivars'][v:beval_text]
    endif

    " See if the cursor is over a feature.
    if l:line_end =~ 'has\s*(.\w\+$' &&
            \ has_key(g:TagmaTipsSettings['vim']['feature'], v:beval_text)
        return g:TagmaTipsSettings['vim']['feature'][v:beval_text]
    endif

    " Default to nothing.
    " This will cause TipsExpr() to check spelling as a last resort.
    return []
endfunction
