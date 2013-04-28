#!/bin/sh

# This script is not for invoking directly. It is for use in conjunction (as a "callback") with
# git-diff-puppet: this script will be looking for the .tmp_git_diff file

# Called with "load" argument when initialized by parent script, and with "refresh" when called by FS watcher.
# second argument is passed through from the parent command, and is the session name to use with.


SHORTDIR=${PWD##*/}
TMPNAME=".tmp_git_diff_$SHORTDIR"
SESSION=${2:-git-diff-puppet}

[[ ! -f "$TMPNAME" ]] && echo "puppet-onchange.sh: $TMPNAME not found; i was probably invoked in error, aborting" && exit 1
if [[ $1 = "load" ]]; then
    echo "onchg: got load"
    if [[ $TMUX && ${TERM:0:6} = 'screen' ]]; then
        # in tmux right now. Make it show up in a new window.
        tmux new-window -n "puppet-$SHORTDIR" git-diff-puppet-command
    else # not currently in tmux; run it from here
        if tmux has-session -t "$SESSION"; then
            # session already present. Attempt to insert window into it
            if ! tmux lsw -F 'window: #{window_name}' -t "$SESSION" | grep "puppet-$SHORTDIR"
            then
                # create window
                tmux new-session -d -s "gd-puppet-aux-$SHORTDIR" -t "$SESSION"
                tmux new-window -n "puppet-$SHORTDIR" -t "$SESSION" git-diff-puppet-command
                tmux attach -t "gd-puppet-aux-$SHORTDIR"
                #new session without a name is made with view into session.
            else # window is there
                exit 2
            fi
        else
            # a git-diff-puppet session does not exist yet, making it
            tmux new-session -n "puppet-$SHORTDIR" -s "$SESSION" git-diff-puppet-command
            # tmux set -t git-diff-puppet allow-rename off # should run prior to shell performing the rename
        fi
    fi
    git diff > "$TMPNAME" # save diff for next comparison
else # refresh (files have potentially changed: quit tmux with no error to re-start
    # diffing the current diff with the saved diff to see if we should re-show the git diff in tmux
    if ! git diff | diff - "$TMPNAME" > /dev/null; then
        tmux kill-window -t "$SESSION:puppet-$SHORTDIR" # kill the thing (could just have it send q)
        # TODO: use updated session here ... maybe session should always get updated?
    # else
        # testing - doing something
        # echo "got a FS callback but not changed!"
    fi # if not changed, do nothing
fi
