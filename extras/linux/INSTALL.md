To install vim projects as a separate filetype in Linux:
--------------------------------------------------------

These instructions tell you how to associate the extension ".vip" with the mimetype "application/vim-project" for the current user, with a note in parentheses how to do it for all users where applicable.

* Copy open-vimproject to somewhere on your PATH and make sure it's executable
* Copy open-vimproject.desktop to ~/.local/share/applications (/usr/share/applications for all users)
* Install the mime type with this command (run as root for all users):
    $ xdg-mime install vimproject-mime.xml
* Set the default application with this command (run as root for all users):
    $ xdg-mime default open-vimproject.desktop application/vim-project
* You might also be able to change the icon with this command, but I haven't been able to get it to work:
    $ xdg-icon-resource install --context mimetypes --size 48 /usr/share/icons/hicolor/48x48/apps/gvim.png x-application-vimproject
