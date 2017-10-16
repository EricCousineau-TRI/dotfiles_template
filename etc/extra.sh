#!/bin/bash

alias historyn="history | sed 's/^[ ]*[0-9]\+[ ]*//'"
alias ll='ls -AlF'
sfe()
{
	for d in $(find . -mindepth 1 -maxdepth 1 -type d)
	do
		( cd $d; eval "$@"; )
	done
}

gz-kill() {
    kill -9 $(pgrep -f gzserver) $(pgrep -f gazebo) 2> /dev/null
    echo "Gazebo death"
}

git-version-setup() {
	# Proper method?
	local prefix=~/local/lib/git
	export PATH=$prefix/bin:$prefix/libexec/git-core:$PATH
	export-prepend MANPATH $prefix/share/man
	# Devel
	export-prepend PATH ~/devel/git/git/contrib/remote-helpers
}

git-script-link() {
	# For development
	pushd $gitws/git
		local script=$1
		rm $1
		ln -s $script.sh $script
		install_path=$(which $script)
		rm $install_path
		ln -s ~+/$script.sh $install_path
		chmod +x $install_path
	popd
}

git-aware() {
	export GITAWAREPROMPT=~/.bash/git-aware-prompt
	# From: https://github.com/jimeh/git-aware-prompt (mentioned by Dane in Confluence)
	# This solution doesn't screw up bash's ability to count characters so you don't get weird line wrapping when editing old lines
	source $GITAWAREPROMPT/main.sh
	export PS1="\[$bldgrn\]\u@\h\[$bldblu\] \w\[$bldylw\]\$git_branch\[$txtcyn\]\$git_dirty\[$txtrst\]\$ "

	short-git-prompt() {
		short-git-cmd() {
			my_host=workstation
			my_dir="$(basename "$PWD")"
		}
		PROMPT_COMMAND="find_git_branch; find_git_dirty; short-git-cmd"
		export PS1="\[$txtcyn\]\$my_dir\[$bldylw\]\$git_branch\[$txtcyn\]\$git_dirty\[$txtrst\]\$ "
	}
}

cling-setup()
{
	cling=~/local/lib/cling
	export-append MANPATH $cling/share/man
	export-append PATH $cling/bin
	export-append LD_LIBRARY_PATH $cling/lib
}

git-full-clone()
{
    (
    set -e -u
    repo="$1"
    dir="$(basename "$repo" .git)"

    git clone "$repo" "$dir"
    cd $dir
    git sfe -t -r 'git sube set-url super && yes | git sube refresh -T --no-sync --reset'

    remote=local
    git remote add $remote "$(git config remote.origin.url)"
    git checkout -- .gitmodules
    git sube set-url -r --remote origin repo -g
    git sube set-url -r --remote $remote super
    )
}

symlink-make-rel() { (
    # NOTE: Use `ln -sr ...` in git-new-workdir from now on
    # Relink using ln -srfT
    set -e -u
    path=${1-.}
    local links=$(find ${path} -type l)
    for link in $links; do
        local link_deref=$(readlink -f $link)
        if [[ -f "${link_deref}" ]]; then
            set -x
            ln -srfT $link_deref $link
            set +x
        fi
    done
) }

symlink-make-rel-workdir() { (
    set -e -u
    path=${1-.}
    gitdirs=$(find $path -name orig_workdir | xargs -n 1 bash -c 'dirname $1' _)
    for gitdir in $gitdirs; do
        (
        echo $gitdir
        cd $gitdir
        test -f orig_workdir || echo "Nope"
        ll
        symlink-make-rel .
        ll
        echo -e "\n\n\n\n\n\n\n\n"
        )
    done
) }

repair-new-workdir() { (
    # Attempt to stitch back together a screwy new-workdir
    set -e -u -x
    path=${1}
    cd $path
    test -f $path/.git/orig_workdir || { eecho "Not a workdir" && false; }
    orig_workdir=$(cat $path/.git/orig_workdir)
    new_head=$(cat $path/.git/HEAD)
    echo $orig_workdir
    rm -rf $path/.git
    git-new-workdir --force --no-checkout --ignore-submodules $orig_workdir .
    echo "$new_head" > $path/.git/HEAD
    git reset
) }
