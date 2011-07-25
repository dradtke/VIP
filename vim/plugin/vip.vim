"====================================================================================================
" File: plugin/vip.vim
" Author: Damien Radtke (admin at damienradtke.org)
" Version: 0.1
"====================================================================================================

if &cp || exists('g:vip_plugin_loaded')
	finish
endif
let g:vip_plugin_loaded = 1

if has("gui")
	" Create a menu item for opening projects
	function! BrowseForProject()
		let result = browse(0, "Open VIP Project", getcwd(), "*.vip")
		if result != ""
			call vip#Open(result)
		endif
	endfunction

	command! OpenProject call BrowseForProject()
	au GUIEnter * menu 10.315 &File.&Open\ VIP\ Project\.\.\.<Tab>:OpenProject <Esc>:call BrowseForProject()<cr>
endif
