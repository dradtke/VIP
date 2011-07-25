VIP
===

VIP is a modular project-management plugin for Vim. Unlike other Vim project plugins that serve primarily as a file browser with features, VIP doesn't offer any file-browsing functionality. Instead, VIP's primary purpose is to offer a "project file," similar to Visual Studio's .sln, that you can open to have your project in Vim ready to go.

Designed primarily for use with a graphical version of Vim, much of VIP's functionality can be discovered via the toolbar. When a project is open, a new men item "Project" will appear, letting you know what you can do with your project via VIP.

The VIP project file is designed similarly to Linux desktop files. Right now you have to manually create one for each project, but the syntax is fairly straightforward. The beginning of each one should look something like this:

    [Vim Project]
    Name=<project name>

Underneath the name can be any number of `Property=Value` pairs, each of them defining various aspects of the project. Right now the following properties are supported:

* `Name` - required; the name of your project
* `Compiler` - optional; the vim compiler to use, e.g. gcc or ant
* `Targets` - optional; a comma-separated list of non-default build targets, e.g. compile,package,clean
* `Exec` - optional; the shell command that will run your project

The line `[Vim Project]` is a *header*, and this must be the first line of the file. Other supported headers should come after all project properties are defined. Defining a header changes how the text following it is interpreted. Right now the following headers are supported:

* `[Vim Project]` - required; must be the first line, and is followed by the project properties
* `[In]` - optional; everything after this header will be sourced as vimscript when the project is opened
* `[Out]` - optional; everything after this header will be sourced as vimscript when the project is closed

Mime and filetype
-----------------

When opening a VIP project from inside Vim, the file's extension or mimetype doesn't matter so long as it's properly formatted and can be read as plain text. One of the purposes of the VIP plugin, however, is to make it possible to double-click on a project file from the file browser and have it open up your project in gVim. The `extras/` folder contains tools for creating a new mimetype based on the extension ".vip", as well as getting it to open up in Vim when double-clicked.

Right now only Linux is supported. Read the INSTALL file for more details.
