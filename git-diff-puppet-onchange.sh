#!/bin/sh

# This script is not for invoking directly. It is for use in conjunction (as a "callback") with
# git-diff-puppet: this script will be looking for the .tmp_git_diff file

# Called with "load" argument when initialized by parent script, and called without any args
# when invoked by the FS watcher.
set -e

SHORTDIR=${PWD##*/}
TMPNAME=".tmp_git_diff_$SHORTDIR"
[[ ! -f "$TMPNAME" ]] && echo "puppet-onchange.sh: $TMPNAME not found; i was probably invoked in error, aborting" && exit 1
if [[ $1 == "load" ]]; then
	echo "onchg: got load"

	# diffing the current diff with the saved diff to see if we should re-show the git diff in tmux
	if ! tmux has-session -t git-diff-puppet; then
		# a git-diff-puppet session does not exist here, making it
		tmux new-session -n "puppet-$SHORTDIR" -s git-diff-puppet "sh -c \"git diff | cat; echo 'DONE WITH $SHORTDIR (originally the first)'; sleep 5;\"" # pipe to cat to skip pager
		tmux set -t git-diff-puppet allow-rename off # should run prior to shell performing the rename
	else
		# a git-diff-puppet session already exists, put me in a new window
		tmux new-window -d -n "puppet-$SHORTDIR" -t git-diff-puppet "sh -c \"git diff | cat && echo 'DONE WITH $SHORTDIR'; sleep 5;\"" # just gotta put a read for q
	fi
	git diff > "$TMPNAME" # save diff for next comparison
else # interrupt (files have potentially changed: quit tmux with no error to re-start
	if ! git diff | diff - "$TMPNAME" > /dev/null; then
		tmux kill-window -t "git-diff-puppet:puppet-$SHORTDIR" # kill the session (could just have it send q)
	else
		# testing - doing something
		echo "got a FS callback but not changed!"
	fi # if not changed, do nothing
fi