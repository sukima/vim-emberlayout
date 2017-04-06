" Description: Emlayout command for opening Ember files in windows
" Author: Devin Weaver <suki@tritarget.org>
" License: MIT

if exists('g:loaded_emberlayout')
	finish
endif
let g:loaded_emberlayout = 1

command! -nargs=? -complete=file Emlayout call emberlayout#open(<f-args>)
