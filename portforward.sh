#!/bin/bash
#
# portforward.sh [-t|-u] <internalip> <port> <externalip> [<port>]

protocol=tcp
network=$ESI_NETWORK
subnet=$ESI_NETWORK_SUBNET

usage() {
  echo "$0: usage: $0 [-t|-u] <internalip> <port> <externalip> [<port>]"
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

while getopts tun: ch; do
  case $ch in
  t) protocol=tcp ;;
  u) protocol=udp ;;
  n) network=$OPTARG ;;
  s) subnet=$OPTARG ;;
  *)
    usage >&2
    exit 2
    ;;
  esac
done
shift $((OPTIND - 1))

if ! (($# >= 3)); then
  usage >&2
  exit 2
fi

[[ -z "$network" ]] || die "you must provide a network name"
[[ -z "$subnet" ]] || subnet="${network}-subnet"

internalip=$1
internalport=$2
externalip=$3
externalport=${4:-$internalport}

# find or create port with the given internal ip
internalip_port=$(openstack port list --fixed-ip subnet="$subnet",ip-address="$internalip" -f value -c id 2>/dev/null)
if [[ -z "$internalip_port" ]]; then
  internalip_port=$(openstack port create --network "$network" --fixed-ip subnet="$subnet",ip-address="$internalip" "$name" -f value -c id)
fi

[[ -z "$internalip_port" ]] && die "failed to allocate port for address $internalip"

openstack floating ip port forwarding create "$externalip" \
  --protocol "$protocol" \
  --internal-ip-address "$internalip" --internal-protocol-port "$internalport" \
  --external-protocol-port "$externalport" \
  --port "$internalip_port"
