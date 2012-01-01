" Tagma Tool Tips/Balloon Plugin
" vim:foldmethod=marker
" File:         autoload/TagmaTips.vim
" Last Changed: Sun, Jan 1, 2012
" Maintainer:   Lorance Stinson @ Gmail ...
" Home:         https://github.com/LStinson/TagmaTips
" License:      Public Domain
"
" Description:
" Autoloaded code for TagmaTips.
" Contains generic code and settings.

" Plugin version.
let g:TagmaTips#version = 20120101

" The path to this script.
" Useful for caching or loading specific files..
let g:TagmaTipsAutoloadPath = expand('<sfile>:p:h')

" TagmaTips#ProcScan -- Scan the current buffer for procedures. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side effect:
"   Updates b:ToolTipsUserProcs with the discovered procedures.
function! TagmaTips#ProcScan()
    let b:ToolTipsUserProcs = {}
    let l:eof = line('$')
    let l:lnum = 1
    let l:blank = 0
    " Scan for procedure definitions.
    while l:lnum <= l:eof
        let l:line = getline(l:lnum)
        if match(l:line, b:ToolTipsRegexpBlank) >= 0
            let l:blank = l:lnum
            let l:lnum = l:lnum + 1
            continue
        endif
        let l:matches = matchlist(l:line, b:ToolTipsRegexpProc)
        if len(l:matches) != 0
            " Save the procedure.
            let l:proc = l:matches[2]
            let b:ToolTipsUserProcs[l:proc] = []
            call extend(b:ToolTipsUserProcs[l:proc],[l:matches[1], ''])
            " Try to find the description.
            let l:def_lnum = l:blank + 1
            while l:def_lnum < l:lnum && l:def_lnum > l:lnum - 30
                call add(b:ToolTipsUserProcs[l:proc], getline(l:def_lnum))
                let l:def_lnum = l:def_lnum + 1
            endwhile
        endif
        let l:lnum = l:lnum + 1
    endwhile
endfunction " }}}1

" TagmaTips#SetupBuffer -- Setup the tool tips for the current buffer. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side effect:
"   An autocmd is created to scan procedures when the buffer is written.
"   Settings are updated to enable the tool tips.
function! TagmaTips#SetupBuffer()
    " Bail if there are no settings for this file type.
    if !has_key(g:TagmaTipsSettings, &ft)
        return 0
    endif

    " User defined procedures.
    let b:ToolTipsUserProcs = {}

    " Balloon settings.
    setlocal bexpr=TagmaTips#TipsExpr()
    setlocal ballooneval

    " Save these for faster lookup.
    let b:ToolTipsRegexpBlank = g:TagmaTipsSettings[&ft]['blank']
    let b:ToolTipsRegexpProc = g:TagmaTipsSettings[&ft]['proc']

    " Load the file type specific settings.
    if !has_key(g:TagmaTipsSettings[&ft], 'loaded')
        let g:TagmaTipsSettings[&ft]['loaded'] = 1
        "silent! execute 'call TagmaTips' . &ft . '#LoadSettings()'
        execute 'call TagmaTips' . &ft . '#LoadSettings()'
    endif

    " Autocommand to update the procedure list.
    au BufWritePost <buffer> call TagmaTips#ProcScan()

    " Initialize the local procedure list.
    call TagmaTips#ProcScan()
endfunction " }}}1

" TagmaTips#TipsExpr -- Callback to return the tooltip text. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side effect:
"   Returns the tooltip for the word under the cursor.
function! TagmaTips#TipsExpr()
    let l:word = v:beval_text
    let l:tool_tip = []

    " Get the user procedures and type for the taget buffer.
    let l:userprocs = getbufvar(v:beval_bufnr, 'ToolTipsUserProcs')
    let l:type = getbufvar(v:beval_bufnr, '&filetype')

    " Search for the word under the cursor.
    if has_key(l:userprocs, l:word)
        " User Procedures
        let l:tool_tip = l:userprocs[l:word]
    elseif has_key(g:TagmaTipsSettings[l:type]['prim'], l:word)
        " Language Primitive
        let l:tool_tip = g:TagmaTipsSettings[l:type]['prim'][l:word]
    elseif has_key(g:TagmaTipsSettings[l:type]['vars'], l:word)
        " Language Variables
        let l:tool_tip = g:TagmaTipsSettings[l:type]['vars'][l:word]
    else
        " See if this file type has a custom expression.
        if has_key(g:TagmaTipsSettings[l:type], 'expr')
            execute 'let l:tool_tip = ' .g:TagmaTipsSettings[l:type]['expr']
        endif

        " Spelling as a fallback.
        if len(l:tool_tip) == 0
            let l:tool_tip = spellsuggest(spellbadword(v:beval_text)[0], 25)
        endif
    endif
    
    return join(l:tool_tip, has("balloon_multiline") ? "\n" : " ")
endfunction " }}}1
