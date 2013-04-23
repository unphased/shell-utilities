#!/bin/sh

# This script runs git diff through tmux at the current directory, so that you can
# interactively scroll it. Listens for changes to the filesystem at this directory
# and tmux is used to issue commands to reload the diff.
set -e

[[ -f .tmp_git_diff ]] && echo "found .tmp_git_diff, exiting" && exit -1
# save the current git diff string to use for comparison
git diff > .tmp_git_diff
function cleanup {
	kill $FSWATCHPID
	rm .tmp_git_diff
	tmux kill-session -t git-diff-puppet
}
trap cleanup EXIT
tmux new-session -d -s git-diff-puppet sh

# here be some proof-of-concept key remapping that can be done through tmux.
# tmux set terminal-overrides "*:kf8=\\033[15~,*:kf7=\\033[17~"
# tmux bind -n F8 send-keys "<[]>"
# tmux bind -n F7 send-keys "<{}>"

tmux send-keys -t git-diff-puppet "echo \"testing this command\" && sleep 1" enter
git-diff-puppet-onchange.sh load
fswatch . ~/util/git-diff-puppet-onchange.sh &
FSWATCHPID=$!
tmux attach -t git-diff-puppet
echo "tmux finished: puppet script exiting"
