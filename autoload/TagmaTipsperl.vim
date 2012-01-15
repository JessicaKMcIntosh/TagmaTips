" Tagma Tool Tips settings for Perl.
" vim:foldmethod=marker
" File:         autoload/TagmaTipsperl.vim
" Last Changed: Sun, Jan 1, 2012
" Maintainer:   Lorance Stinson @ Gmail ...
" Home:         https://github.com/LStinson/TagmaTips
" License:      Public Domain
"
" Description:
" Perl specific settings for the Tagma Tool Tips Plugin

" Make sure the continuation lines below do not cause problems in
" compatibility mode.
let s:cpo_save = &cpo
set cpo-=C

" TagmaTipsperl#LoadSettings -- Load the Perl Settings. {{{1
"   Loads the Perl specific settings into g:TagmaTipsSettings.
"
" Arguments:
"   None
"
" Result:
"   None
"
" Side Effects:
"   Updates g:TagmaTipsSettings.
function! TagmaTipsperl#LoadSettings()

    " Perl tool tips function.
    let g:TagmaTipsSettings['perl']['expr'] = 'TagmaTipsperl#TipsExpr()'

    " Load Perl Primitives from 'TagmaTipsperlprim.vim'.
    " This file can be regenerated from 'misc/perl_func.pl'.
    call TagmaTipsperlprim#LoadPrim()

    " Set the definition for '-X'. " {{{2
    let g:TagmaTipsSettings['perl']['_prim']['-X'] = [
    \   '-X FILEHANDLE; -X EXPR; -X DIRHANDLE',
    \   'A file test, where X is one of the letters listed below.',
    \   '',
    \   '        -r  File is readable by effective uid/gid.',
    \   '        -w  File is writable by effective uid/gid.',
    \   '        -x  File is executable by effective uid/gid.',
    \   '        -o  File is owned by effective uid.',
    \   '        -R  File is readable by real uid/gid.',
    \   '        -W  File is writable by real uid/gid.',
    \   '        -X  File is executable by real uid/gid.',
    \   '        -O  File is owned by real uid.',
    \   '        -e  File exists.',
    \   '        -z  File has zero size (is empty).',
    \   '        -s  File has nonzero size (returns size in bytes).',
    \   '        -f  File is a plain file.',
    \   '        -d  File is a directory.',
    \   '        -l  File is a symbolic link.',
    \   '        -p  File is a named pipe (FIFO), or Filehandle is a pipe.',
    \   '        -S  File is a socket.',
    \   '        -b  File is a block special file.',
    \   '        -c  File is a character special file.',
    \   '        -t  Filehandle is opened to a tty.',
    \   '        -u  File has setuid bit set.',
    \   '        -g  File has setgid bit set.',
    \   '        -k  File has sticky bit set.',
    \   '        -T  File is an ASCII text file (heuristic guess).',
    \   '        -B  File is a "binary" file (opposite of -T).',
    \   '        -M  Script start time minus file modification time, in days.',
    \   '        -A  Same for access time.',
    \   '        -C  Same for inode change time (Unix, may differ for other platforms)',
    \ ] " }}}2

    " Perl Primitive Aliases. {{{2
    let g:TagmaTipsSettings['perl']['palias'] = {
                \   '-r': '-X',
                \   '-w': '-X',
                \   '-x': '-X',
                \   '-o': '-X',
                \   '-R': '-X',
                \   '-W': '-X',
                \   '-X': '-X',
                \   '-O': '-X',
                \   '-e': '-X',
                \   '-z': '-X',
                \   '-s': '-X',
                \   '-f': '-X',
                \   '-d': '-X',
                \ } " }}}2

    " Perl Variables. {{{2
    let g:TagmaTipsSettings['perl']['_vars'] = {
    \ } " }}}2

endfunction " }}}1

" TagmaTipsperl#TipsExpr() -- Perl tool tip lookup function. {{{1
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
function! TagmaTipsperl#TipsExpr()
    " Get the line the cursor is over.
    let l:tip_line = getbufline(v:beval_bufnr, v:beval_lnum, v:beval_lnum)[0]

    " First part of the line to the cursor position.
    let l:line_start = strpart(l:tip_line, 0, v:beval_col)

    " See if the cursor is over a -X function.
    let l:test_word = '-' . v:beval_text
    if l:line_start =~ '-\a$' &&
            \ has_key(g:TagmaTipsSettings['perl']['palias'], l:test_word)
        return g:TagmaTipsSettings['perl']['_prim'][
                    \g:TagmaTipsSettings['perl']['palias'][l:test_word]]
    endif

    " Default to nothing.
    " This will cause TipsExpr() to check spelling as a last resort.
    return []
endfunction " }}}1

" Restore the saved compatibility options.
let &cpo = s:cpo_save
unlet s:cpo_save
