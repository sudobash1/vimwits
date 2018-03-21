" This file is part of VimWits. Copyright Stephen Robinson, 2017
"
" VimWits is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 2 of the License, or
" (at your option) version 3.
"
" VimWits is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with VimWits.  If not, see <http://www.gnu.org/licenses/>.

if !exists("g:loaded_vimwits")
  echoe "vimwits not loaded!"
  finish
endif

" SECTION: helper functions {{{

" Setup the autocmds
" If buf_local is true, then setup the autocmds for the current
" buffer instead of globally.
func s:au_setup(buf_local)
  if a:buf_local
    let l:group = "vimwits_buf"
    let l:pats = "<buffer>"
  else
    let l:group = "vimwits"
    let l:pats = escape(g:vimwits_ft_patterns, " \	")
  endif

  exe "augroup " . l:group
    exe "autocmd CursorMoved " . l:pats . " call s:do_highlight('n')"
    if exists('##CursorMovedI')
      exe "autocmd CursorMovedI " . l:pats .
        \ " if g:vimwits_in_insert | call s:do_highlight('i') | endif"
    endif
    if exists('##WinEnter')
      exe "autocmd WinEnter " . l:pats . " call s:force_do_highlight()"
      exe "autocmd WinLeave " . l:pats . " call s:clear()"
    endif
    if exists('##FocusLost')
      exe "autocmd FocusLost " . l:pats . " call s:clear()"
    endif
    if exists('##TextChanged')
      exe "autocmd TextChanged " . l:pats . " call s:do_highlight('n')"
    endif
    " The below isn't needed because changing the text in insert mode
    " should also move the cursor.
    "if exists('##TextChangedI')
    "  exe "autocmd TextChangedI " . l:pats .
    "    \ " if g:vimwits_in_insert | call s:do_highlight('i') | endif"
    "endif
    if exists('##InsertEnter')
      exe "autocmd InsertLeave " . l:pats . " call s:do_highlight('n')"
      exe "autocmd InsertEnter " . l:pats .
        \ " if !g:vimwits_in_insert | call s:clear() | else |" .
        \ " call s:do_highlight('i') | endif"
    endif
    if exists('##VimResized')
      exe "autocmd VimResized " . l:pats . " call s:do_highlight('n')"
    endif

    if exists('##User')
      exe "autocmd User " . l:pats . " let b:__vimwits_has_au = 1"
    endif
  augroup END
endfunc

func s:clear()
  if exists("w:vimwits_match")
    call matchdelete(w:vimwits_match)
    unlet w:vimwits_match
    unlet w:vimwits_oldMatchWord
  endif
endfunc

func s:do_highlight(mode)

  if a:mode == "i"
    " We are in insert mode. Try looking behind the cursor
    " (where we have been typing) to see if there is a word there.
    let l:pos = getpos(".")
    normal! h
    let l:cword = escape(expand('<cword>'), '/\' )
    let l:col = col('.')
    call setpos('.', l:pos)
  else
    let l:cword = escape(expand('<cword>'), '/\' )
    let l:col = col('.')
  endif

  " Test if enabled and on a valid word
  if l:cword == "" || l:cword=~g:vimwits_ignore ||
        \ g:vimwits_enable == 0 || getbufvar('%', "vimwits_enable", 1) == 0
    call s:clear()
    return
  endif

  " Test if the cursor is actually on <cword>
  if !(matchstr(getline('.'), '\%'.l:col.'c.') =~# '\k')
    if a:mode == "i" && !(matchstr(getline('.'), '\%'.col(".").'c.') =~# '\k')
      call s:clear()
      return
    endif
  endif

  let l:syn = vimwits#syntax_group()

  if exists('b:vimwits_valid_hi_groups')
    if b:vimwits_valid_hi_groups != [] &&
          \ index(b:vimwits_valid_hi_groups, l:syn) == -1
      " We are filtering valid higlight groups in this buffer and the cursor
      " isn't in the correct one
      call s:clear()
      return
    endif
  elseif g:vimwits_valid_hi_groups != [] &&
        \ index(g:vimwits_valid_hi_groups, l:syn) == -1
    " We are filtering valid higlight groups and the cursor isn't in the
    " correct one
    call s:clear()
    return
  endif

  if getwinvar('%', "vimwits_oldMatchWord", "") == l:cword
    " Already matching this word. Don't bother searching again.
    return
  endif

  call s:clear()

  let w:vimwits_oldMatchWord = l:cword

  let l:topline = line("w0") - 1
  let l:botline = line("w$") + 1
  let l:match_re = '\V\%>'.l:topline.'l\%<'.l:botline.'l\<'.l:cword.'\>'

  let w:vimwits_match = matchadd("VimWitsMatch", l:match_re)

endfunction

func s:force_do_highlight()
  call s:clear()
  call s:do_highlight('n')
endfunc

" }}}

" SECTION: Interface functions {{{
func vimwits#init()
  let g:vimwits_enable = 1
  for l:b in range(bufnr("$"))
    call setbufvar(l:b, "__vimwits_has_au", 0)
  endfor
  call vimwits#reset()
endfunc

func vimwits#reset()
  for l:b in range(bufnr("$"))
    call setbufvar(l:b, "vimwits_enable", 1)
  endfor
  if g:vimwits_enable
    call s:au_setup(0)
    call s:do_highlight('n')
  else
    call vimwits#disable()
  endif
endfunc

func vimwits#enable_buf()
  " Make sure vimwits is enabled
  let g:vimwits_enable = 1
  call s:au_setup(0)
  call s:do_highlight('n')

  " Use the User autocmd to test if this buffer already has autocommands
  let b:__vimwits_has_au = 0
  silent doautocmd vimwits User

  if getbufvar('%', "__vimwits_has_au", 0) == 0
    call s:au_setup(1)
    let b:__vimwits_has_au = 1
  endif
  let b:vimwits_enable = 1

  call s:do_highlight('n')
endfunc

func vimwits#disable_buf()
  let b:vimwits_enable = 0
  call s:clear()
endfunc

func vimwits#disable_bufs()
  for l:b in range(bufnr("$"))
    call setbufvar(l:b, "__vimwits_has_au", 0)
  endfor
  augroup vimwits_buf
    au!
  augroup END
  call s:do_highlight('n')
endfunc

func vimwits#disable()
  let g:vimwits_enable = 0
  augroup vimwits
    au!
  augroup END
  call s:clear()
endfunc

func vimwits#syntax_group()
  return synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")
endfunc

" vim:ft=vim:fdm=marker
