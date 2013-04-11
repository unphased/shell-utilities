#!/bin/sh
#
# tmux - ensure that my tmux command (in reality _tmux) gets run with the right options

_tmux -2 -S ~/.tmp/tmux/default "$@"
