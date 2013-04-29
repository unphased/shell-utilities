#!/bin/sh

# This script is not for invoking directly. It is for use in conjunction (as a "callback") with
# git-diff-puppet: this script will be looking for the .tmp_git_diff file

# Called with "load" argument when initialized by parent script, and with "refresh" when called by FS watcher.
# second argument is passed through from the parent command, and is the session name to use with.

SHORTDIR=${PWD##*/}
SHORTDIR=${SHORTDIR//./_dot_}
SHORTDIR=${SHORTDIR//:/_colon_}

TMPNAME=".tmp_git_diff_$SHORTDIR"
SESSION="puppet-$SHORTDIR"
[[ ! -f "$TMPNAME" ]] && echo "puppet-onchange.sh: $TMPNAME not found; i was probably invoked in error, aborting" && exit 1
if [[ $1 = "load" ]]; then
    if [[ $TMUX && ${TERM:0:6} = 'screen' ]]; then
        {
            unset TMUX # to allow for nesting. be sure not to mess around with these too hard
            tmux new-session -s "$SESSION" git-diff-puppet-command \; set -q status-right '#[bg=magenta]#[fg=black] Nested Puppet TMUX '
        }
    else
        tmux new-session -s "$SESSION" git-diff-puppet-command
    fi
    git diff > "$TMPNAME" # save diff for next comparison
else # refresh (files have potentially changed: quit tmux with no error to re-start
    # diffing the current diff with the saved diff to see if we should re-show the git diff in tmux
    if ! git diff | diff - "$TMPNAME" > /dev/null; then
        tmux send-keys -t "$SESSION" enter r #enter ensures exiting from copy mode
    fi # if not changed, do nothing
fi
