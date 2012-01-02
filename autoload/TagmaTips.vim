" TagmaTips Tagma Tool Tips/Balloon Plugin
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
let g:TagmaTips#version = 20120102

" The path to this script.
" Useful for caching or loading specific files..
let g:TagmaTipsAutoloadPath = expand('<sfile>:p:h')

" TagmaTips#CacheLoad -- Load cache data for a file type. {{{1
"   Loads cache data for a file type.
"   The version is verified to prevent compatibility issues.
"
" Arguments:
"   type        The file type to load for.
"
" Result:
"   True if the cache data was loaded.
"
" Side Effects:
"   Updates g:TagmaTipsSettings with the cache data.
function! TagmaTips#CacheLoad(type)
    " Cache file name.
    let l:cache_file = g:TagmaTipsAutoloadPath . '/Cache' . a:type . '.txt'
    if !filereadable(l:cache_file)
        return 0
    endif

    " Load the cache data.
    let l:cache_data = readfile(l:cache_file)
    if len(l:cache_data) == 0
        return 0
    endif

    " Check the version.
    if l:cache_data[2] != g:TagmaTips#version
        return 0
    endif

    " Store the cache data into g:TagmaTipsSettings.
    call extend(g:TagmaTipsSettings[a:type],eval(l:cache_data[3]))

    " Return success.
    return 1
endfunction " }}}1

" TagmaTips#CacheSave -- Save cache data for a file type. {{{1
"   Saves settings from g:TagmaTipsSettings to a cache file.
"   The plugin version is saved in the cache file for checking on load.
"
" Arguments:
"   type        The file type to save for.
"   keys        A list of keys to save.
"
" Result:
"   True if the cache data was saved.
"
" Side Effects:
"   A cache file is created in the autoload directory.
"   CAche files are named 'Cache#.txt' where '#' is the file type.
function! TagmaTips#CacheSave(type, keys)
    " Cache file name.
    let l:cache_file = g:TagmaTipsAutoloadPath . '/Cache' . a:type . '.txt'

    " The dictionary that will be written to the cache file.
    let l:cache_data = {}

    " Store the requested keys into l:cache_data.
    for l:key in a:keys
        if has_key(g:TagmaTipsSettings[a:type], l:key)
            let l:cache_data[l:key] = g:TagmaTipsSettings[a:type][l:key]
        endif
    endfor

    " Write the data to the cache file.
    let l:result = writefile([
                \   '# Cache file for ' . a:type . ' Tool Tips.',
                \   '# DO NOT MODIFY!!',
                \   g:TagmaTips#version,
                \   string(l:cache_data),
                \ ],
                \ l:cache_file
                \ )

    " Return the status of the write.
    return (l:result == 0)
endfunction " }}}1

" TagmaTips#ProcScan -- Scan the current buffer for procedures. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side Effects:
"   Updates b:TagmaToolTipsProcs with the discovered procedures.
function! TagmaTips#ProcScan()
    let b:TagmaToolTipsProcs = {}
    let l:eof = line('$')
    let l:lnum = 1
    let l:blank = 0
    " Scan for procedure definitions.
    while l:lnum <= l:eof
        let l:line = getline(l:lnum)
        if match(l:line, b:ToolTipsRegexpBlank) >= 0
            let l:blank = l:lnum
            let l:lnum += 1
            continue
        endif
        let l:matches = matchlist(l:line, b:ToolTipsRegexpProc)
        if len(l:matches) != 0
            " Save the procedure.
            let l:proc = l:matches[2]
            let b:TagmaToolTipsProcs[l:proc] = []
            call extend(b:TagmaToolTipsProcs[l:proc],[l:matches[1], ''])
            " Try to find the description.
            let l:def_lnum = l:blank + 1
            while l:def_lnum < l:lnum && l:def_lnum > l:lnum - g:TagmaTipsLineLimit
                call add(b:TagmaToolTipsProcs[l:proc], getline(l:def_lnum))
                let l:def_lnum += 1
            endwhile
        endif
        let l:lnum += 1
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
" Side Effects:
"   Settings are updated to enable the tool tips.
"   File type specific settings are loaded.
"   An autocmd is created to scan procedures when the buffer is written.
function! TagmaTips#SetupBuffer()
    " Bail if there are no settings for this file type.
    if !has_key(g:TagmaTipsSettings, &filetype)
        return 0
    endif

    " User defined procedures.
    let b:TagmaToolTipsProcs = {}

    " Balloon settings.
    setlocal bexpr=TagmaTips#TipsExpr()
    setlocal ballooneval

    " Save these for faster lookup.
    let b:ToolTipsRegexpBlank = g:TagmaTipsSettings[&filetype]['blank']
    let b:ToolTipsRegexpProc = g:TagmaTipsSettings[&filetype]['proc']

    " Load the file type specific settings.
    if !has_key(g:TagmaTipsSettings[&filetype], 'loaded')
        let g:TagmaTipsSettings[&filetype]['loaded'] = 1
        "silent! execute 'call TagmaTips' . &filetype . '#LoadSettings()'
        execute 'call TagmaTips' . &filetype . '#LoadSettings()'
    endif

    " Autocommand to update the procedure list.
    au BufWritePost <buffer> call TagmaTips#ProcScan()

    " Initialize the local procedure list.
    call TagmaTips#ProcScan()
endfunction " }}}1

" TagmaTips#StoreTip -- Store a tool tip in g:TagmaTipsSettings. {{{1
"   Truncates the tool tip body to g:TagmaTipsLineLimit rows.
"
" Arguments:
"   type        The file type.
"   key         The key to store to.
"   name        The name of the tool tip.
"   body        The tool tip body.
"
" Result:
"   None
"
" Side Effects:
"   The tool tip body is stored in g:TagmaTipsSettings.
function! TagmaTips#StoreTip(type, key, name, body)
    " Bail if there are no settings for this file type.
    if !has_key(g:TagmaTipsSettings, &filetype)
        return 0
    endif

    " Bail if there is no name.
    if a:name == ''
        return
    endif

    " Limit the body 
    let l:body = a:body
    if len(l:body) > g:TagmaTipsLineLimit
        let l:body = l:body[0:(g:TagmaTipsLineLimit - 1)]
        call add(l:body, '...')
    endif

    " Save the tool tip.
    let g:TagmaTipsSettings[a:type][a:key][a:name] = l:body
endfunction " }}}1

" TagmaTips#TipsExpr -- Callback to return the tooltip text. {{{1
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side Effects:
"   Returns the tooltip for the word under the cursor.
function! TagmaTips#TipsExpr()
    let l:word = v:beval_text
    let l:tool_tip = []

    " Get the user procedures and type for the taget buffer.
    let l:userprocs = getbufvar(v:beval_bufnr, 'TagmaToolTipsProcs')
    let l:type = getbufvar(v:beval_bufnr, '&filetype')

    " Search for the word under the cursor.
    if has_key(l:userprocs, l:word)
        " User Procedures
        let l:tool_tip = l:userprocs[l:word]
    elseif has_key(g:TagmaTipsSettings[l:type]['prim'], l:word)
        " Language Primitive
        let l:tool_tip = g:TagmaTipsSettings[l:type]['prim'][l:word]
    elseif has_key(g:TagmaTipsSettings[l:type]['vars'], l:word)
        " Language Variable
        let l:tool_tip = g:TagmaTipsSettings[l:type]['vars'][l:word]
    elseif has_key(g:TagmaTipsSettings[l:type]['palias'], l:word)
        " Language Primitive Alias
        let l:word = g:TagmaTipsSettings[l:type]['palias'][l:word]
        if  has_key(g:TagmaTipsSettings[l:type]['prim'], l:word)
            let l:tool_tip = g:TagmaTipsSettings[l:type]['prim'][l:word]
        endif
    elseif has_key(g:TagmaTipsSettings[l:type]['valias'], l:word)
        " Language Variables Alias
        let l:word = g:TagmaTipsSettings[l:type]['valias'][l:word]
        if  has_key(g:TagmaTipsSettings[l:type]['vars'], l:word)
            let l:tool_tip = g:TagmaTipsSettings[l:type]['vars'][l:word]
        endif
    elseif has_key(g:TagmaTipsSettings[l:type], 'expr')
        " Execute the file type custom lookup function.
        execute 'let l:tool_tip = ' .g:TagmaTipsSettings[l:type]['expr']
    endif
    
    return join(l:tool_tip, has("balloon_multiline") ? "\n" : " ")
endfunction " }}}1
