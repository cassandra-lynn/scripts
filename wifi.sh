#!/bin/bash
# a small tool for connecting to wifi networks
#
# mostly a wrapper for iw, iwconfig and wpa_supplicant
#

########### defaults
verbose=false
url="www.google.com" # url for test pinging

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

function connected() {
    ping $url -c 1 &>/dev/null && return 0 || return 1
}

########### functions

# scans for and outputs the SSIDs of available wifi networks
# with verbose mode, also indicates BSS identifier, signal strength, and security measures
function scan() {
    getinterface
    if $verbose; then
        echo "Scanning for networks..." && \
            iw dev $interface scan | grep -e "$interface" -e "signal:" -e "SSID" -e "RSN" -e "WPA" -e "WPS" -e "Privacy:" || \
                echo "No networks found!" && exit 1
    else
        iw dev $interface scan | grep -e "SSID" | sed "s/[[:space:]]*SSID:[[:space:]]//" || \
            exit 1
    fi
}

# kills all running instances of wpa_supplicant and iw dev
function disconnect() {
    pkill wpa_supplicant 
    pkill "iw dev" 
}

# takes an SSID, then connects to it using $interface
# automatically uses highest level of security
function connect() {
    disconnect
    getinterface
    if [ "$sec" == "WPA" ] || [ "$sec" == "WPA2" ]; then
        $verbose && echo "Using wpa_supplicant to connect."
        read -s -p "WiFi Password: " password
        echo
        $verbose && echo "Connecting to $1..."
        wpa_supplicant -D nl80211,wext -i $interface -c <(wpa_passphrase "$1" "$password") &> /dev/null &
        unset $password
    else
        $verbose && echo "Using iw to connect."
        read -s -p "WiFi Password: " password
        echo
        iw dev $interface connect "$1" key 0:$password &
        unset $password
    fi
}

########### parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-v] [-hSD] [-u url] [-s sec] [-C wifi_name] 
         -S         scan for available wifi networks, print their SSIDs, and exit
         -D         disconnect from all wifi networks and exit
         -u url     specify url for test pinging when connecting
         -s sec     treat this wifi connection like sec security type (e.g. WPA2, WEP)
         -C ssid    connect to network with an SSID of ssid and exit
         -h         display this message and exit
         -v         activate verbose mode
                     * without verbose mode, will silently error
EOF
}
if [ $EUID = 0 ]; then
    while getopts "vhSDC:u:s:" opt; do
        case $opt in
            v) verbose=true ;;
            h) usage; exit 0 ;;
            S) scan; exit 0 ;;
            D) disconnect; exit 0 ;;
            C) connect "$OPTARG" ; 
                $verbose && dhcpcd $interface || dhcpcd $interface &>/dev/null
                exit 0 ;;
            s) sec="$OPTARG" ;;
            u) url="$OPTARG" ;;
            ?) usage; exit 1 ;;
        esac
    done
else
    echo "This script must be run as root!"
    exit 1
fi

