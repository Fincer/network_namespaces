#!/bin/env bash

set -e
set -u

_dir=$(dirname "${0}")

# Ref: https://lwn.net/Articles/580893/

# NOTE: DNS name resolution (resolv.conf) is found at /etc/netns/${namespace}/resolv.conf

WAN_ACCESS_IFACES="eth0 wlan0 usb0"

. "${_dir}/netns_functions.sh"

#####
# Local-only namespace, no network access.
delete_namespace "nonet"
init_namespace "nonet"

#####
# WAN-only namespace, no LAN access.
namespace="netwan"

ns_bindnic="${WAN_ACCESS_IFACES}"

ns_hostnic="vwan0"
ns_hostnic_ip="10.10.10.1/24"

ns_slavenic="vwan1"
ns_slavenic_ip="10.10.10.2/24"

ns_broadcast="10.10.10.255"

init_netns ${ns_hostnic} ${ns_slavenic} ${namespace}
set_netns ${ns_hostnic} ${ns_hostnic_ip} ${ns_slavenic} ${ns_slavenic_ip} ${ns_broadcast} ${namespace} ${ns_bindnic}

set_iptables_fw_netns "localdnsrule" ${ns_hostnic} ${ns_bindnic}

#####
# Alternative WAN-only network access.
namespace="failsafe"

ns_bindnic="${WAN_ACCESS_IFACES}"

ns_hostnic="vwanf0"
ns_hostnic_ip="10.20.20.1/24"

ns_slavenic="vwanf1"
ns_slavenic_ip="10.20.20.2/24"

ns_broadcast="10.20.20.255"

init_netns ${ns_hostnic} ${ns_slavenic} ${namespace}
set_netns ${ns_hostnic} ${ns_hostnic_ip} ${ns_slavenic} ${ns_slavenic_ip} ${ns_broadcast} ${namespace} ${ns_bindnic}

set_iptables_fw_netns "noextrarule" ${ns_hostnic} ${ns_bindnic}

#####
# Local network without DNS access.
namespace="netlocal"

ns_bindnic="lo"

ns_hostnic="vlocal0"
ns_hostnic_ip="10.30.30.1/24"

ns_slavenic="vlocal1"
ns_slavenic_ip="10.30.30.2/24"

ns_broadcast="10.30.30.255"

init_netns ${ns_hostnic} ${ns_slavenic} ${namespace}
set_netns ${ns_hostnic} ${ns_hostnic_ip} ${ns_slavenic} ${ns_slavenic_ip} ${ns_broadcast} ${namespace} ${ns_bindnic}

set_iptables_fw_netns "nodnsrule" ${ns_hostnic} ${ns_bindnic}
