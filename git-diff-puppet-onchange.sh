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
    echo "onchg: got load"
    if [[ $TMUX && ${TERM:0:6} = 'screen' ]]; then
        # in tmux right now. Make it show up in a new window.
        {
            unset TMUX # to allow for nesting. be sure not to mess around with these too hard
            tmux new-session -s "$SESSION" git-diff-puppet-command \; set -q status-right '#[bg=magenta]#[fg=black] Nested Puppet TMUX '
        }
    else # not currently in tmux; run it from here
        # make a session for each puppet.
        tmux new-session -s "$SESSION" git-diff-puppet-command
        # must exit session to reload

        # TARGETSESSION="$SESSION"
        # tmux has-session -t "$SESSION" && TARGETSESSION="gd-puppet-aux-$SHORTDIR"
        # if [[ "$TARGETSESSION" = "$SESSION" ]]; then
        #     # is gonna be making the specified one rather than an aux-session
        #     # must check to see if any aux sessions exist. If any, join the first one you see
        #     EXISTING=$(tmux list-sessions -F '#{session_name}')
        #     if echo "$EXISTING" | grep "^gd-puppet-aux-"
        #     then
        #         TARGET=$(echo "$EXISTING" | head -n1)
        #         echo "Making session $TARGETSESSION targeting existing session $TARGET"
        #         tmux new-session -d -s "$TARGETSESSION" -t "$TARGET"
        #     else
        #         # no existing sessions appear to be ones we care about
        #         echo "Making initial session $TARGETSESSION"
        #         tmux new-session -d -s "$TARGETSESSION"
        #     fi
        # else
        #     echo "Making session $TARGETSESSION"
        #     tmux new-session -d -s "$TARGETSESSION" -t "$SESSION"
        # fi
        # tmux new-window -n "puppet-$SHORTDIR" -t "$TARGETSESSION" git-diff-puppet-command
        # tmux attach -t "$TARGETSESSION"
        # # done; kill the window
        # tmux kill-window "gd-puppet-aux-$SHORTDIR:puppet-$SHORTDIR"
        # tmux kill-session "gd-puppet-aux-$SHORTDIR"

        # if [[ "$TARGETSESSION" = "$SESSION" ]]; then

        # else

        # fi

        # else
        #     # the specified session does not exist yet, making it
        #     tmux new-session -n "puppet-$SHORTDIR" -s "$SESSION" git-diff-puppet-command
        #     tmux
        # fi
    fi
    git diff > "$TMPNAME" # save diff for next comparison
else # refresh (files have potentially changed: quit tmux with no error to re-start
    # diffing the current diff with the saved diff to see if we should re-show the git diff in tmux
    if ! git diff | diff - "$TMPNAME" > /dev/null; then
        tmux send-keys -t "$SESSION" enter r #enter ensures exiting from copy mode
    # else
        # testing - doing something
        # echo "got a FS callback but not changed!"
    fi # if not changed, do nothing
fi
