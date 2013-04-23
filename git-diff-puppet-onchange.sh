#!/bin/sh

# This script is not for invoking directly. It is for use in conjunction (as a "callback") with
# git-diff-puppet: this script will be looking for the .tmp_git_diff file
set -e

[[ ! -f .tmp_git_diff ]] && echo ".tmp_git_diff not found; i was probably invoked in error, aborting" && exit 1
# diffing the current diff with the saved diff to see if we should re-show the git diff in tmux
if ! git diff | diff - .tmp_git_diff > /dev/null || [[ $1 == "load" ]] ; then
	# the Ctrl+L here is for keeping the less output from drifting down on changes
	# the enter after q is to ensure it does not break when running on shell to start with
	tmux send-keys -t git-diff-puppet q enter C-l "git diff" enter
	# tmux send-keys -t git-diff-puppet q enter C-l "{ git status && git diff }" enter
	git diff > .tmp_git_diff
fi