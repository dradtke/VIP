#!/bin/bash

if [[ `whoami` == root ]]; then
	echo "Installing as root..."
else
	# Install the desktop file
	mkdir -p ~/.local/share/applications && cp vip-open.desktop ~/.local/share/applications

	# Install the mime
	xdg-mime install vimproject-mime.xml

	# Set default application (the new desktop file)
	# [this isn't working right now; seems to need kde-config]
	xdg-mime default vip-open.desktop application/vim-project

	# Install the icon
	# [this probably won't work either, but I haven't checked]
	xdg-icon-resource install --context mimetypes --size 48 gvim.png x-application-vim-project
fi
