" Author: Stephen Robinson <sblazerobinson@gmail.com>
" Version: 0.2
"
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

if exists("g:loaded_vimwits") || &cp
  finish
endif

let g:loaded_vimwits    = 0.2

if !exists("##CursorMoved") || v:version < 700
  echoerr "Unable to use VimWits."
  echoerr ""
  echoerr "Vimwits requres vim >= 7.0 with CursorMoved compiled in."
endif

let s:keepcpo           = &cpo
set cpo&vim

" ------------------------------------------------------------------------------

" Global Variables {{{
if !exists("g:vimwits_enable")
  let g:vimwits_enable = 1
endif
if !exists("g:vimwits_ft_patterns")
  let g:vimwits_ft_patterns = "*.c,*.cpp,*.cxx,*.hxx,*.h,*.hpp,*.C,*.H,
                              \*.py,*.pl,*.cs,*.java,*.php,*.js,*.rb,*.go,*.mm"
endif
if !exists("g:vimwits_in_insert")
  let g:vimwits_in_insert = 1
endif
if !exists("g:vimwits_valid_hi_groups")
  let g:vimwits_valid_hi_groups = [""]
endif
if !exists("g:vimwits_ignore")
  let g:vimwits_ignore = "^[0-9]"
endif

highlight default VimWitsMatch term=underline cterm=underline gui=underline
" }}}

command VimWitsEnable call vimwits#init()
command VimWitsDisable call vimwits#disable()

command VimWitsEnableBuf call vimwits#enable_buf()
command VimWitsDisableBuf call vimwits#disable_buf()
command VimWitsDisableBufs call vimwits#disable_bufs()

if g:vimwits_enable
  " Initialize when we enter a buffer of the correct type
  let s:pats = escape(g:vimwits_ft_patterns, " \	")
  augroup vimwits
    exe "autocmd! BufEnter " . s:pats . " call vimwits#init()"
  augroup END
endif

" ------------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo

" vim:ft=vim:fdm=marker
