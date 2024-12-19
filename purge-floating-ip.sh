#!/bin/bash

for ip in "$@"; do
  openstack floating ip port forwarding list "$ip" -f value -c id |
    xargs -r -n1 openstack floating ip port forwarding delete "$ip"
done
