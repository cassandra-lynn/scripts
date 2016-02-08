#!/bin/bash
# a small tool for connecting to wifi networks
#
# mostly a wrapper for iw, iwconfig and wpa_supplicant
#

########### defaults
verbose=false

########### helper functions

# sets $interface to the first interface that is wifi-capable
# if no interfaces are found, exit with an error
function getinterface() {
    interfaces=( $(iwconfig 2>/dev/null | sed s/[[:space:]].*// | sed -n 's/./&/p') ) # parse iwconfig and make an array out of stdout
    if [ "${interfaces[@]}" == "" ]; then # if there are no interfaces
        $verbose && echo "No wireless interfaces found!"
        exit 1
    else
        interface="${interfaces[0]}"
    fi
}

########### functions
function scan() {
    getinterface
    $verbose && iw dev $interface scan | grep -e "$interface" -e "signal:" -e "SSID" -e "RSN" -e "WPA" -e "WPS" -e "Privacy:"
    ! $verbose && iw dev $interface scan | grep -e "SSID" | sed s/[[:space:]]*SSID:[[:space:]]//
}

#function disconnect() {
#    
#}

#function connect() {
#
#}

########### parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-v] [-hSD] [-C wifi_name]
       -S             scan for available wifi networks and exit
       -D             disconnect from all wifi networks and exit
       -C wifi_name   connect to network named wifi_name and exit
       -h             display this message and exit
       -v             activate verbose mode
                      without verbose mode, will silently error out
EOF
}

while getopts "vhSDC:" opt; do
    case $opt in
        v) verbose=true ;;
        h) usage; exit 0 ;;
        S) scan; exit 0 ;;
        D) disconnect; exit 0 ;;
        C) connect "$OPTARG" ; exit 0 ;;
        ?) usage; exit 1 ;;
    esac
done

