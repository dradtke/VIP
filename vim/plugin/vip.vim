"====================================================================================================
" File: plugin/vip.vim
" Author: Damien Radtke (admin at damienradtke.org)
" Version: 0.1
"====================================================================================================

if &cp || exists('g:vip_plugin_loaded')
	finish
endif
let g:vip_plugin_loaded = 1

command! -nargs=? -complete=file OpenProject call vip#OpenProjectCommand(<f-args>)
command! CloseProject call vip#CloseCurrentProject()
command! CreateProject call vip#CreateNewProject()

" Create a menu item for opening projects
au GUIEnter * menu 10.315 &File.&Open\ VIP\ Project\.\.\.<Tab>:OpenProject <Esc>:call vip#BrowseForProject()<cr>
