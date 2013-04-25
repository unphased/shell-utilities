#!/bin/sh

# This script runs git diff through tmux at the current directory, so that you can
# interactively scroll it. Listens for changes to the filesystem at this directory
# and tmux is used to issue commands to reload the diff.
set -e



SHORTDIR=${PWD##*/}
TMPNAME=".tmp_git_diff_$SHORTDIR"
[[ -f "$TMPNAME" ]] && echo "Found $TMPNAME, aborting" && exit -1

# save the current git diff string to use for comparison
git diff > "$TMPNAME"

function cleanup {
	kill $FSWATCHPID
	rm "$TMPNAME"
	# tmux kill-window -t "git-diff-puppet:puppet-$SHORTDIR"
}
trap cleanup EXIT

# tmux new-session -d -s git-diff-puppet sh

# here be some proof-of-concept key remapping that can be done through tmux.
# tmux set terminal-overrides "*:kf8=\\033[15~,*:kf7=\\033[17~"
# tmux bind -n F8 send-keys "<[]>"
# tmux bind -n F7 send-keys "<{}>"

# tmux send-keys -t git-diff-puppet "echo \"testing this command\" && sleep 1" enter

fswatch . ~/util/git-diff-puppet-onchange.sh refresh $1 &
FSWATCHPID=$!
# tmux attach -t git-diff-puppet

while git-diff-puppet-onchange.sh load $1; do
	echo "Puppet: saw ret $?, reexecuting on $SHORTDIR at `date`, checking"
done
echo "Child errored. Puppet parent script for $SHORTDIR exiting"