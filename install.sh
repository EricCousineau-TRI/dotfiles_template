#!/bin/bash
set -e -u

ln_flags=
while [[ $# -gt 0 ]]; do
    case $1 in
    -f | --force)
        echo "Force Link Overwrite!"
        ln_flags=-f
        ;;
    *)
        echo "Invalid option: $1" >&2
        exit 0
    esac
    shift
done

if [[ -z "$ln_flags" ]]; then
    echo "NOTE: If these files already exist and you wish to overwrite, use the --force flag"
fi


cd $(dirname $BASH_SOURCE)

echo "[ bash_aliases ]"
file=bash_aliases
ln $ln_flags -s ~+/$file ~/.$file || echo "erp"

echo "[ bash_completion ]"
file=bash_completion
ln $ln_flags -s ~+/$file ~/.$file || echo "erp"

echo "[ inputrc ]"
file=inputrc
ln $ln_flags -s ~+/$file ~/.$file || echo "erp"

echo "[ git ]"
if ! which git ; then
    sudo apt-get install git || echo "erp"
fi

echo "[ git-aware-prompt ]"
if [[ ! -d ~/.bash/git-aware-prompt ]]; then
    dir=~/.bash
    (
        mkdir -p $dir && cd $dir
        git clone https://github.com/eacousineau/git-aware-prompt.git
    ) || echo "erp"
fi

echo "[ git-util ]"
if [[ ! -d ~/.bash/git-util ]]; then
    dir=~/.bash
    (
        mkdir -p $dir && cd $dir
        git clone https://github.com/eacousineau/util.git git-util
        cd git-util
        mkdir -p ~/local/bin
        ./install ~/local/bin
    ) || echo "erp"
fi

echo "[ gitconfig ]"
file=gitconfig
ln $ln_flags -s ~+/$file ~/.$file || echo "erp"

echo "[ gitignore ]"
dir=~/.config/git
file=gitignore
mkdir -p $dir
ln $ln_flags -s {~+,$dir}/$file || echo "erp"
git config --global core.excludesFile "$dir/$file"

echo "[ bazelrc ]"
file=bazelrc
ln $ln_flags -s ~+/$file ~/.$file || echo "erp"

echo "[ gdbinit ]"
file=gdbinit
ln $ln_flags -s ~+/$file ~/.$file || echo "erp"

echo "[ tmux ]"
file=tmux.conf
ln $ln_flags -s ~+/$file ~/.$file || echo "erp"

echo "[ amber_developer_stack ]"
if [[ ! -d ~/devel/amber_developer_stack ]]; then
    dir=~/devel
    (
        mkdir -p $dir && cd $dir
        git clone https://github.com/eacousineau/amber_developer_stack.git
    ) || echo "erp"
fi

