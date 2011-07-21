" In/Out-file names
let s:out_file = 'out.vim'
let s:in_file = 'in.vim'

" Project-agnostic menus
" Project-specific ones can be created using commands in in.vim
let s:menu_sep = '&Project.-sep-'
let s:close_project = '&Project.&Close'
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

" Returns 1 if a project is open, 0 otherwise
function! vip#IsProjectOpen()
	return has_key(s:current_project, 'name')
endfunction

" Closes the current project
function! vip#CloseCurrentProject()
	if has_key(s:current_project, 'name')
		" Source the outfile, if applicable
		if has_key(s:current_project, 'out')
			execute 'source '.s:current_project['out']
		endif

		" Tear down the menu
		call vip#TeardownMenu()
	endif
	
	" Reset the dict
	let s:current_project = {}
endfunction

" Opens a confirmation dialog for closing the project, and if OK is selected,
" the project is closed
function! vip#CloseCurrentProjectDialog()
	if confirm("Close the current project?", "&OK\n&Cancel") == 1
		call vip#CloseCurrentProject()
	endif
endfunction

" Open a vim project
function! vip#Open(file)
	" Make sure the file exists and is readable
	if !filereadable(a:file)
		echoerr "File doesn't exist or is not readable: '".a:file."'"
		return
	endif

	" Read in the file
	let lines = readfile(a:file)

	" Make sure it appears to be a valid file
	if tolower(lines[0]) != "[vim project]"
		echoerr "File doesn't appear to be a valid vim project: '".a:file."'"
		return
	endif

	" Create a cache for the new project
	let new_project = {}

	" Loop through line-by-line
	for line in lines
		let eq = match(line, "=") " get the index of the equals sign
		if eq != -1
			let name = strpart(line, 0, eq)
			let value = strpart(line, eq+1)
			let new_project[tolower(name)] = value
		endif
	endfor

	" Make sure a name was supplied
	if !has_key(new_project, 'name')
		echoerr "This project has no name."
		return
	endif

	" Set 'file' to the full path of a:file
	let new_project['file'] = fnamemodify(a:file, ':p')

	" If 'root' wasn't supplied, default to the directory the file's in
	" This assumes it's given as a full path
	if !has_key(new_project, 'root')
		let new_project['root'] = fnamemodify(a:file, ':p:h')
	endif

	" Set the compiler, if provided
	if has_key(new_project, 'compiler')
		execute 'compiler! '.new_project['compiler']
	endif
	
	" TODO: Put other tag recognitions here, e.g. omnifunc?
	
	" CD to the project's root
	execute 'cd '.new_project['root']

	" Save the in and out properties, if the files exist
	" First the infile
	if filereadable(s:in_file)
		let new_project['in'] = new_project['root'].'/'.s:in_file
	endif

	" Now the outfile
	if filereadable(s:out_file)
		let new_project['out'] = new_project['root'].'/'.s:out_file
	endif

	" Do any cleanup of existing projects, if necessary
	call vip#CloseCurrentProject()

	" Set the current project and reset custom menus
	let s:current_project = new_project
	let s:custom_menus = []

	" Make any necessary changes to the menu
	call vip#SetupMenu()

	" Finally, source the infile, if applicable
	if has_key(new_project, 'in')
		execute 'source '.new_project['in']
	endif
endfunction

" Sets up the project menu
function! vip#SetupMenu()
	execute 'menu '.s:menu_sep.' :'
	execute 'menu '.s:close_project.' <Esc>:call vip#CloseCurrentProjectDialog()<cr>'
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
			execute "menu ".menu_item." :call vip#BuildWithTarget('".target."')<cr>"
			call add(s:custom_menus, menu_item)
		endfor
	endif
endfunction

" Tears down project-agnostic menu items
function! vip#TeardownMenu()
	execute 'unmenu '.s:menu_sep
	execute 'unmenu '.s:close_project
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
endfunction

" Compiles the program
function! vip#Build()
	" Vim always has one compiler defined, so just assume that it's right
	make!
endfunction

" Compiles the program using a specific target
function! vip#BuildWithTarget(target)
	execute 'make! '.a:target
endfunction

" Runs the program
function! vip#Exec()
	" Make sure this project can be executed
	if !has_key(s:current_project, 'exec')
		echoerr "No executable for this project was provided."
		return
	endif

	execute '!'.s:current_project['exec']
endfunction

" Runs the program with pre-defined arguments
function! vip#ExecWithArgs(args)
	" Make sure this project can be executed
	if !has_key(s:current_project, 'exec')
		echoerr "No executable for this project was provided."
		return
	endif

	execute '!'.s:current_project['exec'].' '.a:args
endfunction

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

" Gives read-only access to the current project dictionary
function! vip#GetProjectProperty(prop)
	return get(s:current_project, a:prop)
endfunction

" Same as GetProjectProperty(), but returns a default value if nothing is
" found
function! vip#GetProjectPropertyWithDefault(prop, default)
	return get(s:current_project, a:prop, a:default)
endfunction

" Hello World test method
function! vip#HelloWorld()
	echo "hello world"
endfunction
