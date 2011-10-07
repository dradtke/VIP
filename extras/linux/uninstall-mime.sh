#!/bin/bash

if [[ `whoami` == root ]]; then
	# Uninstall as root (for all users)
else
	# Remove the desktop file
	rm -f ~/.local/share/applications/vip-open.desktop

	# Remove the mime
	xdg-mime uninstall vimproject-mime.xml

	# Uninstall the icon
	xdg-icon-resource uninstall --context mimetypes --size 48 gvim.png x-application-vim-project
fi
