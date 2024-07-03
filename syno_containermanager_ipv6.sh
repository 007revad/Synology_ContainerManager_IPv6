#!/usr/bin/env bash
#------------------------------------------------------------
# Synology enable IPv6 on bridge network in Container Manager
#------------------------------------------------------------
#
# Posted in: 
# https://www.synology-forum.de/threads/container-manager-oder-docker-auf-ipv6-umstellen.134481/post-1179432
#
# Adapted for ContainerManager from DSM6 post here: 
# https://www.synoforum.com/threads/has-anyone-been-successful-in-enabling-ipv6-for-the-docker-daemon.435/
#
#------------------------------------------------------------

# Replace "2001:db8:1::/64" in cidr with your network's cidr range

cidr="2001:db8:1::/64"


#------------------------------------------------------------

scriptver="v1.0.1"
script="Synology_ContainerManager_IPv6"
repo="007revad/Synology_ContainerManager_IPv6"

# Check cidr has been set
if [[ -z "$cidr" ]] || [[ "$cidr" == "2001:db8:1::/64" ]]; then
    echo -e "\nERROR You need to set cidr to your IPv6 cidr range!\n"
    exit 1
fi

# Check script is running as root
if [[ $( whoami ) != "root" ]]; then
    echo -e "\nERROR This script must be run as sudo or root!\n"
    exit 1
fi

# Check script is running in DSM 7
majorversion=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION majorversion)
if [[ $majorversion -lt "7" ]]; then
    echo -e "\nERROR This script only works for DSM 7!\n"
    exit 2
fi

# Check Container Manager is installed
/usr/syno/bin/synopkg status ContainerManager >/dev/null
code="$?"
# DSM 7.2       0 = started, 17 = stopped, 255 = not_installed, 150 = broken
# DSM 6 to 7.1  0 = started,  3 = stopped,   4 = not_installed, 150 = broken
if [[ $code == "255" ]] || [[ $code == "4" ]]; then
    echo -e "\nERROR Container Manager is not installed!\n"
    exit 3
fi

# Stop ContainerManager
echo "Stopping Container Manager"
/usr/syno/bin/synopkg stop ContainerManager >/dev/null

# Files to edit
etc_json="/var/packages/ContainerManager/etc/dockerd.json"
target_json="/var/packages/ContainerManager/target/config/dockerd.json"
start_stop_status="/var/packages/ContainerManager/scripts/start-stop-status"

# Backup dockerd.json files
if [[ ! -f "${etc_json}.bak" ]]; then
    echo "Backing up $etc_json"
    cp -p "$etc_json" "${etc_json}.bak"
fi
if [[ ! -f "${target_json}.bak" ]]; then
    echo "Backing up $target_json"
    cp -p "$target_json" "${target_json}.bak"
fi

# Backup start_stop_status
if [[ ! -f "${start_stop_status}.bak" ]]; then
    echo "Backing up $start_stop_status"
    cp -p "$start_stop_status" "${start_stop_status}.bak"
fi

# Edit etc/dockerd.json
echo "Editing $etc_json"
echo -n '{"data-root":"/var/packages/ContainerManager/var/docker","log-driver":"db","registry-mirrors":[],"storage-driver":"btrfs","ipv6":true,"fixed-cidr-v6":"'"${cidr}"'"}' > "$etc_json"

# Edit target/config/dockerd.json
echo "Editing $target_json"
echo '{' > "$target_json"
echo '	"registry-mirrors": [],' >> "$target_json"
echo '	"data-root": "/var/packages/ContainerManager/target/docker",' >> "$target_json"
echo '	"log-driver": "db",' >> "$target_json"
echo '	"ipv6": true,' >> "$target_json"
echo '	"fixed-cidr-v6": '"$cidr" >> "$target_json"
echo '}' >> "$target_json"

# Replace $DockerUpdaterBin postinst updatedockerdconf "$(get_install_volume_type)"
# With    #$DockerUpdaterBin postinst updatedockerdconf "$(get_install_volume_type)"
echo "Editing $start_stop_status"
sed -i 's/$DockerUpdaterBin postinst/#$DockerUpdaterBin postinst/' "$start_stop_status"

# Start ContainerManager
echo "Starting Container Manager"
/usr/syno/bin/synopkg start ContainerManager >/dev/null

exit

