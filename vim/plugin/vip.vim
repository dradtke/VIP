"====================================================================================================
" File: plugin/vip.vim
" Author: Damien Radtke (admin at damienradtke.org)
" Version: 0.1
"====================================================================================================

if &cp || exists('g:vip_plugin_loaded')
	finish
endif
let g:vip_plugin_loaded = 1

function! s:BrowseForProject()
	let result = browse(0, "Open VIP Project", getcwd(), "*.vip")
	if result != ""
		call vip#Open(result)
	endif
endfunction

function! s:CloseProject()
	if !vip#IsProjectOpen()
		echo "No project is open to close."
		return
	endif

	call vip#CloseCurrentProject()
endfunction

command! OpenProject call s:BrowseForProject()
command! CloseProject call s:CloseProject()

" Create a menu item for opening projects
au GUIEnter * menu 10.315 &File.&Open\ VIP\ Project\.\.\.<Tab>:OpenProject <Esc>:call s:BrowseForProject()<cr>
