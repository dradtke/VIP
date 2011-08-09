"====================================================================================================
" File: plugin/vip.vim
" Author: Damien Radtke (admin at damienradtke.org)
" Version: 0.1
"====================================================================================================

if &cp || exists('g:vip_plugin_loaded')
	finish
endif
let g:vip_plugin_loaded = 1

command! OpenProject call vip#BrowseForProject()
command! CloseProject call vip#CloseCurrentProject()

" Create a menu item for opening projects
au GUIEnter * menu 10.315 &File.&Open\ VIP\ Project\.\.\.<Tab>:OpenProject <Esc>:call vip#BrowseForProject()<cr>
