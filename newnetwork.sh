#!/bin/bash

network_args=()
subnet_args=()
router_args=()

usage() {
  echo "$0: usage: $0 name subnet_range [pool_start:pool_end]"
}

while getopts n:s:r: ch; do
  case $ch in
  n) network_args+=("$OPTARG") ;;
  s) subnet_args+=("$OPTARG") ;;
  r) router_args+=("$OPTARG") ;;
  *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))

(($# >= 2)) || {
  usage >&2
  exit 2
}

net_name="$1"
subnet_name="${1}-subnet"
router_name="${1}-router"
subnet_range=$2
allocation_pool=$3

set -e

network_id=$(
  openstack network show "$net_name" -f value -c id 2>/dev/null ||
    openstack network create "$net_name" -f value -c id "${network_args[@]}"
)
subnet_id=$(
  openstack subnet show "$subnet_name" -f value -c id 2>/dev/null ||
    openstack subnet create "$subnet_name" --network "$network_id" --subnet-range "$subnet_range" \
      ${allocation_pool:+--allocation-pool start="${allocation_pool%:*}",end="${allocation_pool#*:}"} -f value -c id \
      "${subnet_args[@]}"
)
openstack router show "$router_name" >/dev/null 2>&1 || openstack router create "$router_name" "${router_args[@]}" >/dev/null
openstack router set "$router_name" --external-gateway external
openstack router add subnet "$router_name" "$subnet_id" >/dev/null
