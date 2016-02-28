#!/bin/sh

for i in /proc/[0-9]*/fd/*; do 
    var="$(readlink $i)"
    if test x"$var" != x"${var#/dev/snd/pcm}"; then
        ps -p $(echo $i | cut -d / -f3) -o comm=
    fi
done
