#!/bin/sh
# keeps a ~/Desktop folder from being created because fuck that
#
# depends on inotify, rm, and grep
# written by ercas ( www.github.com/ercas/ )
while true; do
    if inotifywait -e create $HOME | grep Desktop$; then
        rm -r Desktop
    fi
done &> /dev/null
