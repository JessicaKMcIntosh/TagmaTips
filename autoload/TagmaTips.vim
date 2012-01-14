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
let g:TagmaTips#version = 20120114

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
    let l:cache_file = g:TagmaTipsCachePath .  a:type . '.txt'
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
"   type        The file type to load for.
"   keys        A list of keys to cache.
"
" Result:
"   True if the cache data was saved.
"
" Side Effects:
"   A cache file is created in the autoload directory.
"   CAche files are named 'Cache#.txt' where '#' is the file type.
function! TagmaTips#CacheSave(type, keys)
    " Make sure keys is a list.
    if type(a:keys) != type([])
        if g:TagmaTipsDebugMode
            echoerr 'ERROR: Invalid parameter, "keys" must be a list.'
            echoerr 'TagmaTips#CacheSave call for file type "' . a:type . '"'
        endif
        return 0
    endif

    " Cache file name.
    let l:cache_file = g:TagmaTipsCachePath  . a:type . '.txt'

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
                \   '# Cache file for ' . &filetype . ' Tool Tips.',
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

        " Keep track of blank lines.
        if match(l:line, b:ToolTipsRegexpBlank) >= 0
            let l:blank = l:lnum
            let l:lnum += 1
            continue
        endif

        " Check for a procedure definition.
        let l:matches = matchlist(l:line, b:ToolTipsRegexpProc)
        if len(l:matches) != 0
            " Save the procedure.
            let l:proc = l:matches[2]
            let l:body = [l:matches[1], '']
            call extend(l:body, getline(l:blank + 1, l:lnum - 1))
            call TagmaTips#StoreTip('', '', l:proc, l:body)
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
    let b:ToolTipsRegexpBlank = g:TagmaTipsSettings[&filetype]['_blank']
    let b:ToolTipsRegexpProc = g:TagmaTipsSettings[&filetype]['_proc']

    " Load the file type specific settings.
    if !has_key(g:TagmaTipsSettings[&filetype], '_loaded')
        let g:TagmaTipsSettings[&filetype]['_loaded'] = 1
        if g:TagmaTipsDebugMode
            execute 'call TagmaTips' . &filetype . '#LoadSettings()'
        else
            silent! execute 'call TagmaTips' . &filetype . '#LoadSettings()'
        endif
    endif

    " Autocommand to update the procedure list.
    autocmd BufWritePost <buffer> call TagmaTips#ProcScan()

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
"   If type is blank the tool tip is stored in b:TagmaToolTipsProcs.
function! TagmaTips#StoreTip(type, key, name, body)
    " Bail if there is no name.
    if a:name == ''
        return 0
    endif

    " Bail if there are no settings for this file type or the key does not
    " exist.
    if a:type != '' && !has_key(g:TagmaTipsSettings, a:type) && 
                     \ !has_key(g:TagmaTipsSettings[a:type], a:key)
        return 0
    endif

    " Make sure the body is a list.
    if type(a:body) == type([])
        let l:body = a:body
    else
        let l:body = [a:body]
    endif

    " Limit the body 
    if len(l:body) > g:TagmaTipsLineLimit
        let l:body = l:body[0:g:TagmaTipsLineLimit - 1]
        call add(l:body, '...')
    endif

    " Save the tool tip.
    if a:type == ''
        let b:TagmaToolTipsProcs[a:name] = l:body
    else
        let g:TagmaTipsSettings[a:type][a:key][a:name] = l:body
    endif
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
    elseif has_key(g:TagmaTipsSettings[l:type]['_prim'], l:word)
        " Language Primitive
        let l:tool_tip = g:TagmaTipsSettings[l:type]['_prim'][l:word]
    elseif has_key(g:TagmaTipsSettings[l:type]['_vars'], l:word)
        " Language Variable
        let l:tool_tip = g:TagmaTipsSettings[l:type]['_vars'][l:word]
    elseif has_key(g:TagmaTipsSettings[l:type]['_palias'], l:word)
        " Language Primitive Alias
        let l:word = g:TagmaTipsSettings[l:type]['_palias'][l:word]
        if  has_key(g:TagmaTipsSettings[l:type]['_prim'], l:word)
            let l:tool_tip = g:TagmaTipsSettings[l:type]['_prim'][l:word]
        endif
    elseif has_key(g:TagmaTipsSettings[l:type]['_valias'], l:word)
        " Language Variables Alias
        let l:word = g:TagmaTipsSettings[l:type]['_valias'][l:word]
        if  has_key(g:TagmaTipsSettings[l:type]['_vars'], l:word)
            let l:tool_tip = g:TagmaTipsSettings[l:type]['_vars'][l:word]
        endif
    elseif has_key(g:TagmaTipsSettings[l:type], '_expr')
        " Execute the file type custom lookup function.
        execute 'let l:tool_tip = ' .g:TagmaTipsSettings[l:type]['_expr']
    endif
    
    return join(l:tool_tip, has("balloon_multiline") ? "\n" : " ")
endfunction " }}}1
