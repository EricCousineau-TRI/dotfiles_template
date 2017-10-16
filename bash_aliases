#!/bin/bash

personal-setup()
{
    export DOTFILES="$(dirname "$(readlink -f "$BASH_SOURCE")")"
	source $DOTFILES/etc/functions.sh

    source $DOTFILES/etc/extra.sh
	git-aware
	short-git-prompt
}

# <action>
personal-setup
