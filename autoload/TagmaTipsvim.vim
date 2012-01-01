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
"   Sets 'expr' to 'TagmaTipsvim#TipsExpr()' for finding tool tips.
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

    " See if the 'eval.txt' help file is readable.
    let l:eval_file = fnamemodify(&helpfile, ':h') . '/eval.txt'
    if !filereadable(l:eval_file)
        return 0
    endif

    " Internal variables, builtin functions and features.
    let g:TagmaTipsSettings['vim']['ivars'] = {}
    let g:TagmaTipsSettings['vim']['builtin'] = {}
    let g:TagmaTipsSettings['vim']['feature'] = {}

    " Vim tool tips function.
    let g:TagmaTipsSettings['vim']['expr'] = 'TagmaTipsvim#TipsExpr()'

    " Attempt to load the tool tip data from the cache file.
    if g:TagmaTipsEnableCache && s:LoadVimCache()
        return 1
    endif

    " Load tool tip data from eval.txt.
    call s:LoadEval(l:eval_file)

    " Cache the data for faster load next time.
    if g:TagmaTipsEnableCache
        call s:SaveVimCache()
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
endfunction " }}}1

" Utility Functions:

" s:LoadVimCache -- Load tool tip data from a cache file. {{{1
"
" Arguments:
"   None
"
" Result:
"   True if the cache was loaded.
"
" Side effect:
"   Tool tip data is stored in g:TagmaTipsSettings.
function! s:LoadVimCache()
    " Cache file name.
    let l:cache_file = g:TagmaTipsAutoloadPath . '/VimCache.txt'
    if !filereadable(l:cache_file)
        return 0
    endif

    " Load the cache data.
    let l:cache_data = readfile(l:cache_file)
    if len(l:cache_data) == 0
        return 0
    endif

    " Check the version.
    if l:cache_data[1] != g:TagmaTips#version
        return 0
    endif

    " Read the cache data.
    let g:TagmaTipsSettings['vim']['ivars']     = eval(l:cache_data[2])
    let g:TagmaTipsSettings['vim']['builtin']   = eval(l:cache_data[3])
    let g:TagmaTipsSettings['vim']['feature']   = eval(l:cache_data[4])

    " Return success.
    return 1
endfunction " }}}1

" s:LoadEval -- Load tool tip data from eval.txt. {{{1
"   Reads tool tip data from the 'eval.txt' help file.
"
" Arguments:
"   eval_file   The full path to eval.txt.
"
" Result:
"   None
"
" Side Effects:
"   Sets 'ivars' to a list of internal variables from 'eval.txt'.
"   Sets 'builtin' to a list of builtin functions from 'eval.txt'.
"   Sets 'feature' to a list of features from 'eval.txt'.
function! s:LoadEval(eval_file)
    " Read the file looking for internal variable, builtin function
    " definitions and features.
    let l:section = 0           " The current section.
    let l:buried_func = 0       " Buried function definition.
    let l:name = ''             " The name of the tool tip item.
    let l:body = []             " The body of the tool tip item.
    for l:line in readfile(a:eval_file)
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
endfunction " }}}1

" s:SaveVimCache -- Load tool tip data from a cache file. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side Effects:
"   Tool tip data is saved to a text file.
"   The plugin version is saved to prevent issues with format change.
function! s:SaveVimCache()
    " Cache file name.
    let l:cache_file = g:TagmaTipsAutoloadPath . '/VimCache.txt'

    " Write the data to the cache file.
    let l:result = writefile([
                \   '# Cache file for Vim Tool Tips. DO NOT MODIFY!!',
                \   g:TagmaTips#version,
                \   string(g:TagmaTipsSettings['vim']['ivars']),
                \   string(g:TagmaTipsSettings['vim']['builtin']),
                \   string(g:TagmaTipsSettings['vim']['feature']),
                \ ],
                \ l:cache_file
                \ )
endfunction " }}}1

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
" Side Effects:
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
endfunction " }}}1
