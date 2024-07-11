#!/usr/bin/env bash
#------------------------------------------------------------------------------
# Synology enable IPv6 on bridge network in Container Manager or Docker
#
# Github: https://github.com/007revad/Synology_ContainerManager_IPv6
# Script verified at https://www.shellcheck.net/
#
# To run in a shell (replace /volume1/scripts/ with path to script):
# sudo /volume1/scripts/syno_containermanager_ipv6.sh
#------------------------------------------------------------------------------
#
# Posted in: 
# https://www.synology-forum.de/threads/container-manager-oder-docker-auf-ipv6-umstellen.134481/post-1179432
#
# Adapted for ContainerManager from DSM6 post here: 
# https://www.synoforum.com/threads/has-anyone-been-successful-in-enabling-ipv6-for-the-docker-daemon.435/
#
# https://fariszr.com/docker-ipv6-setup-with-propagation/
# https://community.home-assistant.io/t/trying-to-get-matter-to-work-with-synology-how-to-enable-ipv6-for-host-on-container-manager/722157/2
#
#------------------------------------------------------------------------------

# If you are using a scope global IPv6 address replace "fe80::1/64"
# with your network's IPv6 CIDR range.
# For example: cidr="2001:db8:1::/64"

# "fe80::1/64" is for local LAN access only.

cidr="fe80::1/64"


#-----------------------------------------------------------------------

scriptver="v2.0.4"
script="Synology_ContainerManager_IPv6"
repo="007revad/Synology_ContainerManager_IPv6"

if [[ $1 != "-n" ]] || [[ $1 != "--nocolor" ]]; then
    # Shell Colors
    #Black='\e[0;30m'   # ${Black}
    #Red='\e[0;31m'     # ${Red}
    Green='\e[0;32m'    # ${Green}
    #Yellow='\e[0;33m'  # ${Yellow}
    #Blue='\e[0;34m'    # ${Blue}
    #Purple='\e[0;35m'  # ${Purple}
    Cyan='\e[0;36m'     # ${Cyan}
    #White='\e[0;37m'   # ${White}
    Error='\e[41m'      # ${Error}
    Off='\e[0m'         # ${Off}
fi

# Check cidr has been set
if [[ -z "$cidr" ]] || [[ "$cidr" == "2001:db8:1::/64" ]]; then
    echo -e "\n${Error}ERROR${Off} You need to set cidr to your IPv6 cidr range!\n"
    exit 1
fi

# Check script is running as root
if [[ $( whoami ) != "root" ]]; then
    echo -e "\n${Error}ERROR${Off} This script must be run as sudo or root!\n"
    exit 1
fi

# Check script is running in DSM 7.2 or later
buildnumber=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION buildnumber)
if [[ $buildnumber -lt "64555" ]]; then
    echo -e "\n${Error}ERROR${Off} This script only works for DSM 7.2 and later!\n"
    exit 2
fi


# Check Container Manager is installed
/usr/syno/bin/synopkg status ContainerManager >/dev/null
code="$?"
# DSM 7.2       0 = started, 17 = stopped, 255 = not_installed, 150 = broken
if [[ $code == "0" ]] || [[ $code == "17" ]]; then
    Docker="ContainerManager"
fi

# Check Docker is installed
/usr/syno/bin/synopkg status Docker >/dev/null
code="$?"
# DSM 6 to 7.1  0 = started,  3 = stopped,   4 = not_installed, 150 = broken
if [[ $code == "0" ]] || [[ $code == "3" ]]; then
    Docker="Docker"
fi

# Exit if ContainerManager or Docker are not installed
if [[ -z $Docker ]]; then
    echo -e "\n${Error}ERROR${Off} ContainerManager or Docker not installed!\n"
    exit 3
fi


# Show script version
#echo -e "$script $scriptver\ngithub.com/$repo\n"
echo "$script $scriptver"

# Get NAS model
model=$(cat /proc/sys/kernel/syno_hw_version)

# Get DSM full version
productversion=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION productversion)
buildphase=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION buildphase)
buildnumber=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION buildnumber)
smallfixnumber=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION smallfixnumber)

# Show DSM full version and model
if [[ $buildphase == GM ]]; then buildphase=""; fi
if [[ $smallfixnumber -gt "0" ]]; then smallfix="-$smallfixnumber"; fi
echo -e "$model DSM $productversion-$buildnumber$smallfix $buildphase\n"

# Get ContainerManager or Docker version
dockerver=$(/usr/syno/bin/synopkg version "$Docker")

# Show ContainerManager or Docker version
if [[ $dockerver ]]; then echo -e "$Docker $dockerver\n"; fi

#------------------------------------------------------------------------------
# Check latest release with GitHub API

# Get latest release info
# Curl timeout options:
# https://unix.stackexchange.com/questions/94604/does-curl-have-a-timeout
release=$(curl --silent -m 10 --connect-timeout 5 \
    "https://api.github.com/repos/$repo/releases/latest")

# Release version
tag=$(echo "$release" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
#shorttag="${tag:1}"

if ! printf "%s\n%s\n" "$tag" "$scriptver" |
        sort --check=quiet --version-sort >/dev/null ; then
    echo -e "\nThere is a newer version of this script available." |& tee -a "$Log_File"
    echo -e "Current version: ${scriptver}\nLatest version:  $tag" |& tee -a "$Log_File"
fi

#------------------------------------------------------------------------------

# shellcheck disable=SC2317,SC2329  # Don't warn about unreachable commands in this function
pause(){ 
    # When debugging insert pause command where needed
    read -s -r -n 1 -p "Press any key to continue..."
    read -r -t 0.1 -s -e --  # Silently consume all input
    stty echo echok  # Ensure read didn't disable echoing user input
    echo -e "\n"
}

show_json(){ 
    # $1 is file
    # Show target/dockerd.json contents
    echo -e "\nContents of $1" >&2
    if [[ -s "$1" ]]; then
        jq . "$1"
    else
        echo -e "${Error}ERROR${Off} File it empty!" >&2
    fi
}

edit_file(){ 
    # $1 is file
    # $2 is key
    # $3 is value
    # $4 is flat or pretty
    if grep "$2" "$1" | grep -q "$3"; then
        echo "Already contains \"$2\": $3" >&2
    else
        cp -pf "$1" "${1}.tmp"
        #sleep 1

        if [[ ! -s "${1}.tmp" ]]; then
            echo -e "${Error}ERROR${Off} File it empty!" >&2
            return 1
        fi

        if [[ $4 == "flat" ]]; then
            # Save as flat json
            if [[ $2 == "ipv6" ]]; then
                jq -c '. += {"ipv6" : true}' "${1}.tmp" > "$1"
            elif [[ $2 == "fixed-cidr-v6" ]]; then
                jq -c --arg value "$3" '. += {"fixed-cidr-v6" : $value}' "${1}.tmp" > "$1"
            fi
        else
            # Save as pretty json
            if [[ $2 == "ipv6" ]]; then
                jq '. += {"ipv6" : true}' "${1}.tmp" > "$1"
            elif [[ $2 == "fixed-cidr-v6" ]]; then
                jq --arg value "$3" '. += {"fixed-cidr-v6" : $value}' "${1}.tmp" > "$1"
            fi
        fi
    fi
}


# Stop ContainerManager or Docker
if [[ $Docker == "ContainerManager" ]]; then
    echo -e "${Cyan}Stopping${Off} Container Manager\n"
    /usr/syno/bin/synopkg stop ContainerManager >/dev/null
elif [[ $Docker == "Docker" ]]; then
    echo -e "${Cyan}Stopping${Off} Docker\n"
    /usr/syno/bin/synopkg stop Docker >/dev/null
fi

# Files to edit
if [[ $Docker == "ContainerManager" ]]; then
    etc_json="/var/packages/ContainerManager/etc/dockerd.json"
    target_json="/var/packages/ContainerManager/target/config/dockerd.json"
    start_stop_status="/var/packages/ContainerManager/scripts/start-stop-status"
elif [[ $Docker == "Docker" ]]; then
    etc_json="/var/packages/Docker/etc/dockerd.json"
    target_json="/var/packages/Docker/target/config/dockerd.json"
    start_stop_status="/var/packages/Docker/scripts/start-stop-status"
fi

# Backup dockerd.json files
if [[ ! -f "${etc_json}.bak" ]]; then
    echo -e "${Cyan}Backing up${Off} $etc_json"
    cp -p "$etc_json" "${etc_json}.bak"
fi
if [[ ! -f "${target_json}.bak" ]]; then
    echo -e "${Cyan}Backing up${Off} $target_json"
    cp -p "$target_json" "${target_json}.bak"
fi

# Backup start_stop_status
if [[ ! -f "${start_stop_status}.bak" ]]; then
    echo -e "${Cyan}Backing up${Off} $start_stop_status"
    cp -p "$start_stop_status" "${start_stop_status}.bak"
fi

# Edit etc/dockerd.json
echo -e "${Cyan}Checking${Off} $etc_json"
if ! grep 'ipv6' "$etc_json" | grep -q 'true' ||\
    ! grep 'fixed-cidr-v6' "$etc_json" | grep -q "$cidr"; then
    echo -e "Editing $etc_json"
fi
if [[ $Docker == "ContainerManager" ]]; then
    # Save as flat json
    edit_file "$etc_json" ipv6 true flat
    edit_file "$etc_json" fixed-cidr-v6 "$cidr" flat
elif [[ $Docker == "Docker" ]]; then
    # Save as pretty json
    edit_file "$etc_json" ipv6 true flat
    edit_file "$etc_json" fixed-cidr-v6 "$cidr" flat
fi

# Edit target/config/dockerd.json
echo -e "${Cyan}Checking${Off} $target_json"
if ! grep 'ipv6' "$target_json" | grep -q 'true' ||\
    ! grep 'fixed-cidr-v6' "$target_json" | grep -q "$cidr"; then
    echo -e "Editing $target_json"
fi
if [[ $Docker == "ContainerManager" ]]; then
    # Save as pretty json
    edit_file "$target_json" ipv6 true
    edit_file "$target_json" fixed-cidr-v6 "$cidr"
elif [[ $Docker == "Docker" ]]; then
    # Save as pretty json
    edit_file "$target_json" ipv6 true
    edit_file "$target_json" fixed-cidr-v6 "$cidr"
fi

# Cleanup tmp files
[ -f "${etc_json}.tmp" ] && rm "${etc_json}.tmp"
[ -f "${target_json}.tmp" ] && rm "${target_json}.tmp"

# Replace $DockerUpdaterBin postinst updatedockerdconf "$(get_install_volume_type)"
# With    #$DockerUpdaterBin postinst updatedockerdconf "$(get_install_volume_type)"
echo -e "${Cyan}Checking${Off} $start_stop_status"
# shellcheck disable=SC2016
if ! grep -q '#$DockerUpdaterBin postinst' "$start_stop_status"; then
    echo -e "Editing $start_stop_status"
    sed -i 's/$DockerUpdaterBin postinst/#$DockerUpdaterBin postinst/' "$start_stop_status"
else
    echo "Already edited"
fi

# Show dockerd.json contents
show_json "$etc_json"
show_json "$target_json"

# Show ContainerManager/scripts/start-stop-status line
echo -e "\nLine in $start_stop_status"
# shellcheck disable=SC2016
if grep -q '#$DockerUpdaterBin postinst' "$start_stop_status"; then
    line="$(grep '#$DockerUpdaterBin postinst' "$start_stop_status" | xargs)"
    echo -e "  ${Green}$line${Off}"
else
    echo -e "${Error}ERROR${Off} File not edited!"
fi

# Start ContainerManager or Docker
if [[ $Docker == "ContainerManager" ]]; then
    echo -e "\n${Cyan}Starting${Off} Container Manager"
    /usr/syno/bin/synopkg start ContainerManager >/dev/null
elif [[ $Docker == "Docker" ]]; then
    echo -e "\n${Cyan}Starting${Off} Docker"
    /usr/syno/bin/synopkg start Docker >/dev/null
fi

echo -e "\nFinished\n"

exit

