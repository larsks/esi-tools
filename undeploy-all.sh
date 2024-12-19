#!/bin/bash

for node in "$@"; do
  openstack baremetal node undeploy "$node"
done
