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
  # LKS: this would be a handy spot for openstack esi node network detach --all
  echo "detach node from existing network"
  openstack esi node network detach "$node" || :

  echo "attach node to \"$network\" network"
  openstack esi node network attach --network "$network" "$node"

  echo "configure node to boot from disk"
  openstack baremetal node boot device set "$node" disk --persistent
done
