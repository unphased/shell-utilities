#!/bin/sh

# This script runs git diff through tmux at the current directory, so that you can
# interactively scroll it. Listens for changes to the filesystem at this directory
# and tmux is used to issue commands to reload the diff.
set -e

SHORTDIR=${PWD##*/}
SHORTDIR=${SHORTDIR//./_dot_}
SHORTDIR=${SHORTDIR//:/_colon_}
TMPNAME=".tmp_git_diff_$SHORTDIR"
TMPDONE=".tmp_git_diff_done_$SHORTDIR"
[[ -f "$TMPNAME" ]] && echo "Puppet: Found $TMPNAME, aborting" && exit -1

git diff > "$TMPNAME"

function cleanup {
    kill $FSWATCHPID
    rm "$TMPNAME"
    rm "$TMPDONE"
    # tmux kill-window -t "git-diff-puppet:puppet-$SHORTDIR"
}
trap cleanup EXIT

fswatch . "~/util/git-diff-puppet-onchange.sh refresh $1" &
FSWATCHPID=$!

COUNT=0
while git-diff-puppet-onchange.sh load $1 && [[ ! -f "$TMPDONE" ]] && [[ COUNT -lt 100000 ]]; do
    echo "Puppet: saw ret $?, reexecuting on $SHORTDIR at `date`, checking"
    ((COUNT++))
done
echo "COUNT is $COUNT"
echo "Puppet: $SHORTDIR exiting"
