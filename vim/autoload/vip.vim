"====================================================================================================
" File: autoload/vip.vim
" Author: Damien Radtke (admin at damienradtke.org)
" Version: 0.1
"====================================================================================================

" Currently supported .vip file tags:
" -----------------------------------
" Name
" Root
" Compiler
" Targets
" Exec

" {{{ variables
" Headers!
let s:header_pattern = '^\[.*\]$'

let s:header_project = "[vim project]"
let s:header_in = "[in]"
let s:header_out = "[out]"

" Pattern for properties
let s:prop_pattern = '^\(.*\)=\(.*\)$'

" Project-agnostic menus
" Project-specific ones can be created using commands in in.vim
let s:menu_sep = '&Project.-sep-'
let s:close_project = '&Project.&Close\ Project'
let s:build_default = '&Project.&Build.<default>'
let s:run_default = '&Project.&Run.<default>'
let s:run_with_args = '&Project.&Run.&With\ Args\.\.\.'

" Cache for user arguments
let s:exec_args = ""

" keys for s:current_project:
" 	'name' - required
" 	'file' - required, but automatically supplied; do not define
" 	'root' - required; uses the file's directory as a default
" 	'in' - optional; absolute path to in.vim, if available
" 	'out' - optional; absolute path to out.vim, if available
" 	'compiler' - optional; sets the compiler to use
" 	'exec' - optional; specifies the command to run the project
" 	'targets' - optional; comma-separated list of build targets

let s:current_project = {}

" A list of project-specific menus generated by Open()
let s:custom_menus = []

" }}}

" {{{ vip#BrowseForProject()
" Browse for a vim project to open
function! vip#BrowseForProject()
	if !has("browse")
		echoerr "Browsing not supported. Type ':help +browse' for more information."
		return
	endif

	let result = browse(0, "Open VIP Project", getcwd(), "*.vip")
	if result != ""
		call vip#Open(result)
	endif
endfunction
" }}}

" {{{ vip#Open(file)
" Open a vim project
function! vip#Open(filename)
	" Make sure the file exists and is readable
	if !filereadable(a:filename)
		echoerr "File doesn't exist or is not readable: '".a:filename."'"
		return
	endif

	" Read in the file
	let lines = readfile(a:filename)

	" Keep track of the current header
	" The first one should be [vim project]
	let header = tolower(lines[0])

	" Make sure it appears to be a valid file
	if header != s:header_project
		echoerr "File doesn't appear to be a valid vim project: '".a:filename."'"
		return
	endif

	" Create a cache for the new project
	let new_project = {}

	" Store the in-script or out-script
	let in_script = []
	let out_script = []

	" Loop through line-by-line
	for line in lines
		" If this line is a header, update and continue
		if line =~ s:header_pattern
			let header = tolower(line)
			continue
		endif

		if header == s:header_project
			" If the first line is a hash, ignore it; basic commenting support
			if line[0] == '#'
				continue
			endif

			let matched = matchlist(line, s:prop_pattern)
			if len(matched) > 0
				let key = matched[1]
				let value = matched[2]
				let new_project[tolower(key)] = value
			endif
		elseif header == s:header_in
			call add(in_script, line)
		elseif header == s:header_out
			call add(out_script, line)
		endif
	endfor

	" Make sure a name was supplied
	if !has_key(new_project, 'name')
		echoerr "This project has no name."
		return
	endif

	" Set 'file' to the full path of a:filename
	let new_project['file'] = fnamemodify(a:filename, ':p')

	" If 'root' wasn't supplied, default to the directory the file's in
	" This assumes it's given as a full path
	if !has_key(new_project, 'root')
		let new_project['root'] = fnamemodify(a:filename, ':p:h')
	endif

	" Set the compiler, if provided
	if has_key(new_project, 'compiler')
		execute 'compiler! '.new_project['compiler']
	endif

	" If any in-script was given, save it
	if len(in_script) != 0
		let new_project['in'] = in_script
	endif

	" If any out-script was given, save it
	if len(out_script) != 0
		let new_project['out'] = out_script
	endif
	
	" TODO: Put other tag recognitions here, e.g. omnifunc?
	
	" CD to the project's root
	execute 'cd '.new_project['root']

	" Do any cleanup of existing projects, if necessary
	if vip#IsProjectOpen()
		call vip#CloseCurrentProject()
	endif

	" Set the current project and reset custom menus
	let s:current_project = new_project
	let s:custom_menus = []

	" Make any necessary changes to the menu
	call s:SetupMenu()

	" Finally, source the infile, if applicable
	if has_key(new_project, 'in')
		call s:RunScript(new_project['in'])
	endif

	echo "Opened project '".s:current_project['name']."'"
endfunction
" }}}

" {{{ vip#IsProjectOpen()
" Returns 1 if a project is open, 0 otherwise
function! vip#IsProjectOpen()
	return has_key(s:current_project, 'name')
endfunction
" }}}

" {{{ vip#CloseCurrentProject()
" Closes the current project
function! vip#CloseCurrentProject()
	if has_key(s:current_project, 'name')
		" Source the outfile, if applicable
		if has_key(s:current_project, 'out')
			call s:RunScript(s:current_project['out'])
		endif

		" Tear down the menu
		call s:TeardownMenu()

		echo "Closed project '".s:current_project['name']."'"
	else
		echoerr "No project is open to close."
	endif
	
	" Reset the dict
	let s:current_project = {}
endfunction
" }}}

" {{{ vip#CloseCurrentProjectDialog()
" Opens a confirmation dialog for closing the project, and if OK is selected,
" the project is closed
function! vip#CloseCurrentProjectDialog()
	if confirm("Close the current project?", "&OK\n&Cancel") == 1
		call vip#CloseCurrentProject()
	endif
endfunction
" }}}

" {{{ vip#Build()
" Compiles the program
function! vip#Build()
	" Vim always has one compiler defined, so just assume that it's right
	make!
endfunction
" }}}

" {{{ vip#BuildTarget(target)
" Compiles the program using a specific target
function! vip#BuildTarget(target)
	execute 'make! '.a:target
endfunction
" }}}

" {{{ vip#Exec()
" Runs the program
function! vip#Exec()
	" Make sure this project can be executed
	if !has_key(s:current_project, 'exec')
		echoerr "No executable for this project was provided."
		return
	endif

	execute '!'.s:current_project['exec']
endfunction
" }}}

" {{{ vip#ExecWithArgs(args)
" Runs the program with pre-defined arguments
function! vip#ExecWithArgs(args)
	" Make sure this project can be executed
	if !has_key(s:current_project, 'exec')
		echoerr "No executable for this project was provided."
		return
	endif

	execute '!'.s:current_project['exec'].' '.a:args
endfunction
" }}}

" {{{ vip#ExecPromptArgs()
" Prompts the user for arguments, then runs the program
function! vip#ExecPromptArgs()
	" Make sure this project can be executed
	if !has_key(s:current_project, 'exec')
		echoerr "No executable for this project was provided."
		return
	endif

	let new_exec_args = input("Program arguments: ", s:exec_args)

	" If the user hits Escape, a blank string is returned
	" Don't execute if a blank string is returned
	if new_exec_args == ""
		echo "Execution was cancelled"
		return
	endif

	let s:exec_args = new_exec_args
	execute '!'.s:current_project['exec'].' '.s:exec_args
endfunction
" }}}

" {{{ vip#GetProjectProperty(prop)
" Gives read-only access to the current project dictionary
function! vip#GetProjectProperty(prop)
	return get(s:current_project, a:prop)
endfunction
" }}}

" {{{ vip#GetProjectPropertyWithDefault(prop, default)
" Same as GetProjectProperty(), but returns a default value if nothing is
" found
function! vip#GetProjectPropertyWithDefault(prop, default)
	return get(s:current_project, a:prop, a:default)
endfunction
" }}}

" {{{ s:RunScript()
" Sources a script, which is passed in as a list of lines
" Saves the script in the temporary directory and :source's it
function! s:RunScript(script)
	" TODO?: support Windows (uses $TEMP)
	let tmp = $TMPDIR
	let s = "/"

	" Create a file in the temporary directory and write the script to it
	let file = tmp.s.'vip-temp-script'
	if writefile(a:script, file) != 0
		echoerr "ERROR saving temporary script: ".file
		return
	endif

	" Source the script
	execute 'source '.file

	" We're done, remove it
	call delete(file)
endfunction
" }}}

" {{{ s:SetupMenu()
" Sets up the project menu
function! s:SetupMenu()
	execute 'menu '.s:build_default.' <Esc>:make!<cr>'
	
	" Only add run items if 'exec' was defined
	if has_key(s:current_project, 'exec')
		execute 'menu '.s:run_default.' <Esc>:!'.s:current_project['exec'].'<cr>'
		execute 'menu '.s:run_with_args.' <Esc>:call vip#ExecPromptArgs()<cr>'
	endif

	" Integrate custom build targets into the menu
	if has_key(s:current_project, 'targets')
		for target in split(s:current_project['targets'], ',')
			let menu_item = "&Project.&Build.".target
			execute "menu ".menu_item." :call vip#BuildTarget('".target."')<cr>"
			call add(s:custom_menus, menu_item)
		endfor
	endif

	execute 'menu '.s:menu_sep.' :'
	execute 'menu '.s:close_project.' <Esc>:call vip#CloseCurrentProjectDialog()<cr>'
endfunction
" }}}

" {{{ s:TeardownMenu()
" Tears down project-agnostic menu items
function! s:TeardownMenu()
	execute 'unmenu '.s:build_default

	" Remove run items if necessary
	if has_key(s:current_project, 'exec')
		execute 'unmenu '.s:run_default
		execute 'unmenu '.s:run_with_args
	endif

	" Remove custom menus
	for item in s:custom_menus
		execute 'unmenu '.item
	endfor

	execute 'unmenu '.s:menu_sep
	execute 'unmenu '.s:close_project
endfunction
" }}}
