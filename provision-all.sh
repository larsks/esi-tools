#!/bin/bash

while getopts u: ch; do
  case $ch in
  u) discovery_url=$OPTARG ;;
  *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))

[[ -z "$discovery_url" ]] && exit 1

set -e

for node in "$@"; do
  # this would be easier if we had `openstack esi node network detach --all ...`
  # or even something like `openstack esi node network attach --exclusive --network provisioning ...`
  echo "$node: detach all ports"
  openstack esi node network list --node "$node" -f json | jq '.[]|select(.Port != null).Port' -r | xargs -r -IPORT openstack esi node network detach --port PORT "$node"
  echo "$node: set deploy interface"
  openstack baremetal node set --instance-info deploy_interface=ramdisk "$node"
  echo "$node: set boot_iso url"
  openstack baremetal node set --instance-info boot_iso="$discovery_url" "$node"
  echo "$node: attach to provisioning network"
  openstack esi node network attach --network provisioning "$node"
  echo "$node: deploy node"
  openstack baremetal node deploy "$node"
done
