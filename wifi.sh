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

function checknetwork() {
    if $verbose; then
        ping $url -c 1 &>/dev/null && echo "Connected to $1 successfully!" || echo "Did not connect to $1!" && exit 1
    else
        dhcpcd $interface &>/dev/null
        ping $url -c 1 &>/dev/null || exit 1
    fi
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
        iw dev $interface scan | grep -e "SSID" | sed s/[[:space:]]*SSID:[[:space:]]// || \
            exit 1
    fi
}

# kills all running instances of wpa_supplicant and iw dev
function disconnect() {
    pkill wpa_supplicant || exit 1
    pkill "iw dev" || exit 1
    echo "Successfully disconnected!"
}

# takes an SSID, then connects to it using $interface
# automatically uses highest level of security
function connect() {
    getinterface
    #if $1 is WPA or WPA2; then
        #read -s -p "Password: " password
        #echo
        #$verbose && echo "Connecting to $1..."
        #wpa_supplicant -D nl80211,wext -i $interface -c <(wpa_passphrase "$1" "$password") &> /dev/null &
        #password="" # for extra security, i guess
        #sleep 7 # arbitrary time, have noticed that dhcpcd doesn't stick unless you wait a bit
        #$verbose && dhcpcd $interface || dhcpcd $interface &>/dev/null
    #else
        #if $1 is WEP encrypted; then
            #read -s -p "Password: " password
            #echo
            #iw dev $interface connect "$1" key 0:$password &
            #password="" # again, i guess for more security?
        #else
            #iw dev $interface connect "$1" &
        #fi
    #fi
    #checknetwork $1
}

########### parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-v] [-hSD] [-u url] [-C wifi_name]
         -S         scan for available wifi networks, print their SSIDs, and exit
         -D         disconnect from all wifi networks and exit
         -u url     specify url for test pinging when connecting
         -C ssid    connect to network with an SSID of ssid and exit
         -h         display this message and exit
         -v         activate verbose mode
                     * without verbose mode, will silently error
EOF
}

while getopts "vhSDC:u:" opt; do
    case $opt in
        v) verbose=true ;;
        h) usage; exit 0 ;;
        S) scan; exit 0 ;;
        D) disconnect; exit 0 ;;
        C) connect "$OPTARG" ; exit 0 ;;
        u) url="$OPTARG" ;;
        ?) usage; exit 1 ;;
    esac
done

