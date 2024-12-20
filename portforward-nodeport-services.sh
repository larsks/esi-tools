#!/bin/bash

network=$ESI_NETWORK
subnet=$ESI_NETWORK_SUBNET

usage() {
  echo "$0: usage: $0 [-n <namespace>] [-N network] [-S subnet] internal_ip external_ip"
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

while getopts n:S:N: ch; do
  case $ch in
  n) namespace=$OPTARG ;;
  N) network=$OPTARG ;;
  S) subnet=$OPTARG ;;
  *)
    usage >&2
    exit 2
    ;;
  esac
done
shift $((OPTIND - 1))

if (($# != 2)); then
  usage >&2
  exit 2
fi

[[ -z "$network" ]] && die "you must provide a network name"

internalip=$1
externalip=$2

kubectl ${namespace:+-n "$namespace"} get service -o json |
  jq '.items[]|select(.spec.type == "NodePort")|[.metadata.name, .spec.ports[].nodePort]|@tsv' -r |
  while read -r name port; do
    echo "forwarding service $name on port $port"
    sh "$(dirname "$0")/portforward.sh" -d "$name" -n "$network" ${subnet:+-s "$subnet"} "$internalip" "$port" "$externalip"
  done
