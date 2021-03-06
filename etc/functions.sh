#!/bin/bash

# http://musescore.org/en/node/25277#comment-98902
mkcd() {
	# Separate arguments so that -p can be used
	mkdir "$@" && cd "${!#}"
}

alias b="source ~/.bash_aliases"
alias bc="source ~/.bash_completion"
alias bash-isolate='env -i HOME=$HOME DISPLAY=$DISPLAY SHELL=$SHELL TERM=$TERM USER=$USER PATH=/usr/local/bin:/usr/bin:/bin bash --norc'

xcopy() {
	xclip -i -sel clipboard
	echo "[ Clipboard ]"
	echo "$(xclip -o -sel clipboard)"
}
alias copy="xcopy"
xpaste() {
	xclip -o -sel clipboard
}

# Useful for getting full file paths in conjunction with expansion of ~+ (you get tab complete as well)
ecopy() {
	echo -n $@ | xcopy
}

# Home-escaped copy
hecopy() {
	echo -n "$@" | sed "s#^$HOME#~#g" | xcopy
}

alias open='gnome-open'

# For grepping in a file with color, also displaying file name and number - for use with xargs
alias xarg="xargs -n 1"
grepf() {
	grep --color -Hn $@
}
export -f grepf
# Example: find . -maxdepth 4 -name '*.cpp' | grepx 'Test'
grepx() {
	xarg bash -c "grepf '$1' \$1" _
}
# Min-grep - ignore binaries and git directories for better speed
grepm() {
	grep -rnI --exclude-dir=.git --exclude-dir='build*' --exclude-dir='*-build' --exclude-dir='bazel-*' "$@"
}
# Filter grep results: return only file and line number
filt-grep-fl() {
	# @ref http://stackoverflow.com/a/11566589/170413
	cut -d':' -f1-2
}
# Min-grep, only return file name and line number
grepms() {
	grepm "$@" | filt-grep-fl
}

# For finding out what object file has a symbol defined - to be run from the build directory
nm-grep() {
	find . -name '*.o' | xarg bash -c "echo \$1 && nm -C \$1 | grep '$@'" _
	find . -name '*.so' | xarg bash -c "echo \$1 && objdump -T \$1 | c++filt | grep '$@'" _
}

symlink-replace() {
	local sym="$1" orig=
	test ! -L $1 && { eecho "Not a symlink: $1" && return 1; }
	orig="$(readlink -f "$sym")"
	rm "$sym"
	echo "Copied '$orig' to '$sym'"
	cp "$orig" "$sym"
}

# Taken from git-sh-setup
# Find a way to source this file, finding the libexec dir?
# Can just do . git-sh-setup -- will it have too much extra stuff?
die () {
	die_with_status 1 "$@"
}

die_with_status () {
	status=$1
	shift
	eecho "$*"
	exit "$status"
}

# Echo to stderr
eecho() {
	echo >&2 "$*"
}

# Syntactic sugar for prepending / appending to a path-separator delimited list
export-prepend() {
	eval "export $1=\"$2:\${$1-}\""
}
export-append() {
	eval "export $1=\"\${$1-}:$2\""
}
# I think there's already functionality for this... Get rid of it?
export-default() {
	eval "test -z \"\$$1\" && export $1=\"$2\""
}

# Extend an existing FHS environment (PATH, LD_LIBRARY_PATH, pkg-config, etc).
fhs-extend()
{
    local python_version=2.7
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "fhs-extend [--python-version <VERSION>] <PREFIX>"
                return;;
            --python-version)
                python_version=$1
                shift;;
            *)
                break;;
        esac
    done
    local prefix=${1%/}
    export-prepend PATH $prefix/bin
    export-prepend LD_LIBRARY_PATH $prefix/lib
    export-prepend PYTHONPATH $prefix/lib:$prefix/lib/python${python_version}/dist-packages:$prefix/lib/python${python_version}/site-packages
    export-prepend PKG_CONFIG_PATH $prefix/lib/pkgconfig:$prefix/share/pkgconfig
    # MAN path?
    echo "[ FHS Environment extended: ${prefix} ]"
}

# Revert FHS environment variables to what is generally used in `bash-isolate`
fhs-clear() {
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
    export LD_LIBRARY_PATH=
    export PYTHONPATH=
    export PKG_CONFIG_PATH=
    echo "[ FHS Environment reset ]"
}

# Change bash prompt to something minimal so that transcript can be copied and pasted.
minimal-prompt() {
	PROMPT_COMMAND=""
	export PS1="$ "
}

# Return relative path of $1 with respect to $2
# From: git@github.com:eacousineau/util.git:c48bf22:git-submodule-ext.sh:975
rel_path()
{
    test $# -eq 2 || { echo "Must supply two paths" >&2; return 1; }
    local target=$1
    # Add trailing slash, otherwise it won't be robust to common prefixes
    # that don't begin with a /
    local base=$2/

    while test "${target%%/*}" = "${base%%/*}"
    do
        target=${target#*/}
        base=${base#*/}
    done
    # Now chop off the trailing '/'s that were added in the beginning
    target=${target%/}
    base=${base%/}

    # Turn each leading "*/" component into "../", and strip trailing '/'s
    local rel=$(echo $base | sed -e 's|[^/][^/]*|..|g' | sed -e 's|*/+$||g')
    if test -n "$rel"
    then
        echo $rel/$target
    else
        echo $target
    fi
}

# Print out ${repo}:${sha_short}:{rel_path} for a given file path for a Git repo.
git-ref()
{
    use_remote=
    if [[ "$1" == "-r" ]]; then
        use_remote=1
        shift
    fi
    local file="$1"
    # Get repo basename, git file's path, and the sha associated with the file
    repo="$(cd "$(dirname "$file")" && git rev-parse --show-toplevel)"
    rel="$(rel_path $file $repo)"
    if [[ -n "$use_remote" ]]; then
        name="$(git config remote.${REMOTE-origin}.url)"
    else
        name="$(basename $repo)"
    fi
    echo "$name:$(git rev-parse --short HEAD):$rel"
}
