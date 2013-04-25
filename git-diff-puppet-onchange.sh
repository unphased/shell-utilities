#!/bin/sh

# This script is not for invoking directly. It is for use in conjunction (as a "callback") with
# git-diff-puppet: this script will be looking for the .tmp_git_diff file

# Called with "load" argument when initialized by parent script, and with "refresh" when called by FS watcher.
# second argument is passed through from the parent command, and is the session name to use with.
set -e
set -x

SHORTDIR=${PWD##*/}
TMPNAME=".tmp_git_diff_$SHORTDIR"
SESSION=${2:-git-diff-puppet}
CMD='sh -c "git diff | cat; while read -r line; do; [[ $line = "q" ]] && break; done"'
[[ ! -f "$TMPNAME" ]] && echo "puppet-onchange.sh: $TMPNAME not found; i was probably invoked in error, aborting" && exit 1
if [[ $1 == "load" ]]; then
	echo "onchg: got load"

	if tmux has-session -t "$SESSION"; then
		# session already present. Attempt to insert window into it.
		if ! tmux lsw -F #{window_name} -t "$SESSION" | grep "puppet-$SHORTDIR"; then
			# create window
			tmux new-window -n "puppet-$SHORTDIR" -t "$SESSION" "$CMD"
			tmux attach-session -t "$SESSION"
		fi
	else
		# a git-diff-puppet session does not exist here, making it
		tmux new-session -n "puppet-$SHORTDIR" -s "$SESSION" "$CMD"
		# tmux set -t git-diff-puppet allow-rename off # should run prior to shell performing the rename
	fi
	git diff > "$TMPNAME" # save diff for next comparison
else # refresh (files have potentially changed: quit tmux with no error to re-start
	# diffing the current diff with the saved diff to see if we should re-show the git diff in tmux
	if ! git diff | diff - "$TMPNAME" > /dev/null; then
		tmux kill-window -t "$SESSION:puppet-$SHORTDIR" # kill the thing (could just have it send q)
	else
		# testing - doing something
		echo "got a FS callback but not changed!"
	fi # if not changed, do nothing
fi

echo "exiting onchg"