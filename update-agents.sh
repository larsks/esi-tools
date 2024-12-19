#!/bin/bash

workdir=$(mktemp -d workXXXXXX)
trap 'rm -rf "$workdir"' EXIT

echo "get list of agents"
kubectl get agents -o json |
  jq -r '.items[]|[.metadata.name, (.status.inventory.interfaces[]|select(.flags|index("running")).macAddress)]|@tsv' >"$workdir/agents.tab"

while read -r agent macaddr; do
  echo "looking up node with mac address $macaddr"
  node=$(
    openstack baremetal port list --address "$macaddr" -f value -c uuid |
      xargs openstack baremetal port show -f value -c node_uuid |
      xargs openstack baremetal node show -f value -c name
  )

  if [[ -z $node ]]; then
    echo "unable to determine name for agent $agent ($macaddr)" >&2
    continue
  fi

  # ensure node name is lower case
  node=${node,,}
  echo "found node $node"
  kubectl patch agent "$agent" --type json --patch-file /dev/stdin <<EOF
[
{"op": "add", "path": "/spec/hostname", "value": "$node"}
]
EOF
done <"$workdir/agents.tab"
