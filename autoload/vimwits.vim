if !exists("g:loaded_vimwits")
  echoe "vimwits not loaded!"
  finish
endif

" SECTION: helper functions {{{

func s:au_setup(buf_local)
  if a:buf_local
    let l:group = "vimwits_buf"
    let l:pats = "<buffer>"
  else
    let l:group = "vimwits"
    let l:pats = escape(g:vimwits_ft_patterns, " \	")
  endif

  exe "augroup " . l:group
    exe "autocmd CursorMoved " . l:pats . " call s:do_highlight()"
    if g:vimwits_in_insert
      exe "autocmd CursorMovedI " . l:pats . " call s:do_highlight()"
    endif
    if exists('##WinEnter')
      exe "autocmd WinEnter " . l:pats . " call s:force_do_highlight()"
      exe "autocmd WinLeave " . l:pats . " call s:clear()"
    endif
    if exists('##FocusLost')
      exe "autocmd FocusLost " . l:pats . " call s:clear()"
    endif
    if exists('##TextChanged')
      exe "autocmd TextChanged " . l:pats . " call s:do_highlight()"
      if g:vimwits_in_insert
        exe "autocmd TextChangedI " . l:pats . " call s:do_highlight()"
      endif
    endif
    if exists('##InsertEnter')
      exe "autocmd InsertLeave " . l:pats . " call s:do_highlight()"
      if !g:vimwits_in_insert
        exe "autocmd InsertEnter " . l:pats . " call s:clear()"
      endif
    endif
    if exists('##VimResized')
      exe "autocmd VimResized " . l:pats . " call s:do_highlight()"
    endif

    if exists('##User')
      exe "autocmd User " . l:pats . " let b:__vimwits_has_au = 1"
    endif
  augroup END
endfunc

func s:check_enable()
  if g:vimwits_enable == 0
    return 0
  elseif gettabvar('%', "vimwits_enable", 1) == 0
    return 0
  elseif getwinvar('%', "vimwits_enable", 1) == 0
    return 0
  elseif getbufvar('%', "vimwits_enable", 1) == 0
    return 0
  endif
  return 1
endfunc

func s:clear()
  if exists("w:vimwits_match")
    call matchdelete(w:vimwits_match)
    unlet w:vimwits_match
    unlet w:vimwits_oldMatchWord
  endif
endfunc

func s:do_highlight()
  let l:cword = escape(expand('<cword>'), '/\' )

  " Test if enabled and on a valid word
  if l:cword == "" || s:check_enable() == 0 || l:cword=~g:vimwits_ignore
    call s:clear()
    return
  endif

  " Test if the cursor is actually on <cword>
  if ! (matchstr(getline('.'), '\%'.col('.').'c.') =~# '\k')
    call s:clear()
    return
  endif

  let l:syn = vimwits#syntax_group()

  if g:vimwits_valid_hi_groups != [] && index(g:vimwits_valid_hi_groups, l:syn) == -1
    " We are filtering valid higlight groups and the cursor isn't in the correct one
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
  let l:match_re = '\V\%>' . l:topline . 'l\%<' . l:botline . 'l\<' . l:cword . '\>'

  let w:vimwits_match = matchadd("VimWitsMatch", l:match_re)

endfunction

func s:force_do_highlight()
  call s:clear()
  call s:do_highlight()
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
  for l:w in range(winnr("$"))
    call setwinvar(l:w, "vimwits_enable", 1)
  endfor
  for l:t in range(tabpagenr("$"))
    call settabvar(l:t, "vimwits_enable", 1)
  endfor
  if g:vimwits_enable
    call s:au_setup(0)
    call s:do_highlight()
  else
    call vimwits#disable()
  endif
endfunc

func vimwits#enable_buf()
  call vimwits#init()

  " Use the User autocmd to test if this buffer already has autocommands
  silent doautocmd vimwits User

  if getbufvar('%', "__vimwits_has_au", 0) == 0
    call s:au_setup(1)
    let b:__vimwits_has_au = 1
  endif
  let b:vimwits_enable = 1

  call s:do_highlight()
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
  call s:do_highlight()
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
