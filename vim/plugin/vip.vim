let g:vip_loaded = 1
" IDEAS:
" - Create user-configurable options via commands that will write to the
"   project file
" - Support saving the list of open files
" - Support automatically setting up things like make and omnifunctions
" - Create a default window layout? (errors, taglist, etc.)

" If browsing is supported, create a method, command, and menu item for
" opening projects

if has("gui")
	function! BrowseForProject()
		let result = browse(0, "Open VIP Project", getcwd(), "*.vip")
		if result != ""
			call vip#Open(result)
		endif
	endfunction

	command! OpenProject call BrowseForProject()
	au GUIEnter * menu 10.315 &File.&Open\ VIP\ Project\.\.\.<Tab>:OpenProject <Esc>:call BrowseForProject()<cr>
endif
