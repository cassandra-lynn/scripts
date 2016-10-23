#!/bin/sh
[ -d "/home/$(logname)/media/" ] && tmpdir="/home/$(logname)/media" || tmpdir="/tmp"
mntpt="$tmpdir/$(head -c 10 /dev/urandom | base64 | tr -cd '[[:alnum:]]')"
mkdir $mntpt
mount $1 $mntpt
