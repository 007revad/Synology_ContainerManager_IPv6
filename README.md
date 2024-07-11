# Synology Container Manager IPv6

<a href="https://github.com/007revad/Synology_ContainerManager_IPv6/releases"><img src="https://img.shields.io/github/release/007revad/Synology_ContainerManager_IPv6.svg"></a>
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2F007revad%2FSynology_ContainerManager_IPv6&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=views&edge_flat=false"/></a>
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/paypalme/007revad)
[![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/007revad)
[![committers.top badge](https://user-badge.committers.top/australia/007revad.svg)](https://user-badge.committers.top/australia/007revad)
<!-- [![committers.top badge](https://user-badge.committers.top/australia_public/007revad.svg)](https://user-badge.committers.top/australia_public/007revad) -->
<!-- [![committers.top badge](https://user-badge.committers.top/australia_private/007revad.svg)](https://user-badge.committers.top/australia_private/007revad) -->
<!-- [![Github Releases](https://img.shields.io/github/downloads/007revad/synology_containermanager_ipv6/total.svg)](https://github.com/007revad/Synology_ContainerManager_IPv6/releases) -->

### Description

Enable IPv6 for Container Manager's bridge network

The script works in DSM 7 and later.

<p align="left"><img src="/images/success.png"></p>

## Download the script

1. Download the latest version _Source code (zip)_ from https://github.com/007revad/Synology_ContainerManager_IPv6/releases
2. Save the download zip file to a folder on the Synology.
3. Unzip the zip file.

## Edit the script if needed

If your Synology's IPv6 IP address starts with "fe80" you don't need to edit anything.

<p align="left"><img src="/images/cidr.png"></p>

If you are using a scope global IPv6 address replace "fe80::1/64" in the script with your network's IPv6 CIDR range. 

For example: `cidr="2001:db8:1::/64"`

## How to run the script

### Run the script via SSH

[How to enable SSH and login to DSM via SSH](https://kb.synology.com/en-global/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet)

Run the script:

```bash
sudo -s /volume1/scripts/syno_containermanager_ipv6.sh
```

> **Note** <br>
> Replace /volume1/scripts/ with the path to where the script is located.

### Scheduling the script in Synology's Task Scheduler

See <a href=how_to_schedule.md/>How to schedule a script in Synology Task Scheduler</a>

### Screenshots

<p align="left"><img src="/images/screenshot.png"></p>

<br>
