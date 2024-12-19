#!/bin/bash

net_name="$1"
subnet_name="${1}-subnet"
router_name="${1}-router"

set -e

network_id=$(
  openstack network show "$net_name" -f value -c id 2>/dev/null ||
    openstack network create "$net_name" -f value -c id
)
subnet_id=$(
  openstack subnet show "$subnet_name" -f value -c id 2>/dev/null ||
    openstack subnet create "$subnet_name" --network "$network_id" --subnet-range "$2" --allocation-pool start="$3",end="$4" -f value -c id
)
openstack router show "$router_name" >/dev/null 2>&1 || openstack router create "$router_name" >/dev/null
openstack router set "$router_name" --external-gateway external
openstack router add subnet "$router_name" "$subnet_id" >/dev/null
