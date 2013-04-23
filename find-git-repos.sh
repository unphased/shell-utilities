#!/bin/sh

# This is a script that crawls the fs looking for git repos, reminding you which ones
# have changes that potentially need to be committed. I would use spotlight but it does not index
# hidden files/folders.
set -e

#incidentally, this is the script that showed me that homebrew actually sets the
# /usr/local/ directory as a git repo. How crazy is that?

# TODO: keep a cache on the fs so that it can run through last-found repos quickly on start.
# then after that it can go run the find to take as much time as it wants.

DIR=${1:-'.'}

IFS='
'
for repo in `find $DIR -type d -name .git -print 2>/dev/null`; do
	(
		cd $repo/..
		git fetch
		stat=`git status --porcelain`
		if [[ "$stat" == "" ]]; then
			echo "[32m$repo[0m"
			git status | grep "behind" || true #don't care if ret false
		else
			for line in $stat; do
				[[ ! $line =~ ^\?\? ]] && notallunk="1"
			done
			if [[ -z $notallunk ]]; then
				echo "[34m$repo[0m"
				git status | sed "s/^#/[34m#[0m/"
				# echo "[1;34m<<<<[0m $repo [1;34m====[0m"
			else
				echo "    [31m$repo[0m"
				git status | sed "s/^#/[31m#[0m/" | sed "s/^/    /" # indent
				# echo "    [1;31m<<<<[0m $repo [1;31m====[0m"
			fi
		fi
		echo ""
	)
done
