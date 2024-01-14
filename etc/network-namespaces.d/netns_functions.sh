#!/bin/env bash

set -e
set -u

delete_namespace() {

  if [[ ! -z $(ip netns list | grep ${1}) ]]
  then
    ip netns delete ${1}
  fi

}

init_namespace() {

  if [[ -z $(ip netns list | sed -r 's/^(.*) \(.*\)/\1/' | grep -E "^${1}$") ]]
  then
    # Add network namespace ${namespace}
    ip netns add ${1}

    # Bring IPv4 loopback interface up as some applications may require it for minimal networking capabilities
    ip netns exec ${1} ip link set dev lo up
  fi
}

clear_netns() {

  host_vnic=${1}
  nsnic=${2}
  namespace=${3}

  ip netns exec ${namespace} ip link set ${nsnic} down
  ip netns exec ${namespace} ip link del ${nsnic}

  if [[ $(ip link show ${host_vnic} 2>/dev/null) ]]
  then
    ip link set ${host_vnic} down
    ip link del ${host_vnic}
  fi

  delete_namespace ${namespace}

  # TODO clear iptables rules
}

# Bring up all possibly available interfaces
set_netns() {

  host_vnic=${1}
  host_vaddr=${2}
  host_vaddr_nomask=$(echo ${host_vaddr} | sed 's|\/[0-9]*||')
  nsnic=${3}
  nsaddr=${4}
  broadcast=${5}
  namespace=${6}
  host_nics=(${@:7})

  # Add paired virtual interfaces host_vnic (for host) and nsnic (for namespace)
  ip link add ${host_vnic} type veth peer name ${nsnic}

  ip link set ${nsnic} netns ${namespace}

  # Configure network
  ip netns exec ${namespace} ip addr add ${nsaddr} broadcast ${broadcast} dev ${nsnic}
  ip addr add ${host_vaddr} broadcast ${broadcast} dev ${host_vnic}
  ip netns exec ${namespace} ip link set ${nsnic} up
  ip link set ${host_vnic} up

  # Add ARP information as pre-requisite for setting up routing information
  host_vnic_mac=$(ifconfig ${host_vnic} | grep ether | awk '{print $2}')
  ip netns exec ${namespace} arp -s ${host_vaddr_nomask} ${host_vnic_mac}
  ip netns exec ${namespace} ip route add default via ${host_vaddr_nomask}

}

set_iptables_fw_table_rule() {

  table=${1}
  checkrule=${2}
  exists=0

  all_rules=$(iptables -t ${table} -S)

  OLDIFS=${IFS}
  IFS=$'\n'
  for rule in ${all_rules[@]}; do
    if [[ ${rule} == ${checkrule} ]]
    then
      exists=1
      break
    fi
  done
  IFS=${OLDIFS}

  if [[ ${exists} -eq 0 ]]
  then
    iptables -t ${table} ${checkrule}
  fi
}

set_iptables_fw_netns() {

  extrarule=${1}
  host_vnic=${2}
  host_nics=(${@:3})

  echo_reply=0
  echo_request=8

  # Allow internal ping tests
  set_iptables_fw_table_rule "filter" "-A INPUT -i ${host_vnic} -p icmp -m icmp --icmp-type ${echo_reply} -j ACCEPT"
  set_iptables_fw_table_rule "filter" "-A INPUT -i ${host_vnic} -p icmp -m icmp --icmp-type ${echo_request} -j ACCEPT"

  for hnic in ${host_nics[@]}; do
    set_iptables_fw_table_rule "filter" "-A FORWARD -i ${host_vnic} -o ${hnic} -j ACCEPT"
    set_iptables_fw_table_rule "filter" "-A FORWARD -i ${hnic} -o ${host_vnic} -j ACCEPT"
  done

  case ${extrarule} in
    localdnsrule)
      # Optional: if using local or custom DNS server
      # NOTE: Domain resolution: Virtual network addresses must be allowed in /etc/named.conf (quick check: netstat -anp)
      set_iptables_fw_table_rule "filter" "-A INPUT -i ${host_vnic} -p udp -m udp --dport 53 -j ACCEPT"
      set_iptables_fw_table_rule "filter" "-A INPUT -i ${host_vnic} -p tcp -m tcp --dport 53 -j ACCEPT"
      ;;
    nodnsrule)
      set_iptables_fw_table_rule "filter" "-A INPUT -i ${host_vnic} -p udp -m udp --dport 53 -j DROP"
      set_iptables_fw_table_rule "filter" "-A INPUT -i ${host_vnic} -p tcp -m tcp --dport 53 -j DROP"
      ;;
    noextrarule|*)
      ;;
  esac

  set_iptables_fw_table_rule "nat" "-A POSTROUTING -o ${host_vnic} -j MASQUERADE"

}

init_netns() {

  if [[ ! -z $(ip netns list | sed -r 's/^(.*) \(.*\)/\1/' | grep -E "^${3}$") ]]
  then
    clear_netns ${1} ${2} ${3}
  fi

  init_namespace ${3}

}
