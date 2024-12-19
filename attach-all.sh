#!/bin/bash

while getopts n: ch; do
  case $ch in
  n) network=$OPTARG ;;
  *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))

[[ -z "$network" ]] && exit 1

set -e

for node in "$@"; do
  openstack esi node network detach "$node" || :
  openstack esi node network attach --network "$network" "$node"
  openstack baremetal node boot device set "$node" disk --persistent
done
