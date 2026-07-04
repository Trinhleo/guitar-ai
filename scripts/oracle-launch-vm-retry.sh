#!/usr/bin/env bash
# Retry launching an Always Free Ampere A1 VM across availability domains (OCI CLI).
# Designed for Oracle Cloud Shell — no UI clicking when AD-1 is out of capacity.
#
# Examples:
#   ./scripts/oracle-launch-vm-retry.sh --compartment musica-tutor-ai-prod --ssh-key-file ~/.ssh/id_ed25519.pub
#   ./scripts/oracle-launch-vm-retry.sh --compartment musica-tutor-ai-prod --create-network --interval 90
#   ./scripts/oracle-launch-vm-retry.sh --help
set -euo pipefail

COMPARTMENT_NAME=""
COMPARTMENT_ID=""
VM_NAME="musica-tutor-vm"
VCN_NAME="musica-tutor-vcn"
SUBNET_NAME="musica-tutor-public-subnet"
SSH_KEY_FILE=""
SSH_KEY=""
IMAGE_ID=""
SUBNET_ID=""
CREATE_NETWORK=false
OPEN_PORTS=false
DRY_RUN=false
INTERVAL_SEC=60
MAX_ATTEMPTS=0
OCPUS=1
MEMORY_GB=6
FALLBACK_MICRO=false

usage() {
  cat <<'EOF'
Usage: oracle-launch-vm-retry.sh [options]

Automatically retries VM.Standard.A1.Flex launch across all availability domains.
Run from Oracle Cloud Shell (OCI CLI already authenticated).

Required (one of):
  --compartment NAME       Compartment name (e.g. musica-tutor-ai-prod)
  --compartment-id OCID    Compartment OCID

Required:
  --ssh-key-file PATH      SSH public key file (or use --ssh-key with inline key)

Optional:
  --name NAME              Instance display name (default: musica-tutor-vm)
  --create-network         Create VCN + public subnet if none exists in compartment
  --open-ports             Ensure security list allows TCP 22 and 80
  --interval SEC           Seconds between full AD cycles (default: 60)
  --max-attempts N         Stop after N full cycles (0 = retry until success)
  --image-id OCID          Ubuntu image OCID (auto-detected if omitted)
  --subnet-id OCID         Subnet OCID (auto-detected if omitted)
  --ocpus N                A1 Flex OCPUs (default: 1)
  --memory-gb N            A1 Flex memory GB (default: 6)
  --fallback-micro         After max attempts, try VM.Standard.E2.1.Micro (1 GB RAM)
  --dry-run                Print actions without creating resources
  --help                   Show this help

Examples:
  ./scripts/oracle-launch-vm-retry.sh \
    --compartment musica-tutor-ai-prod \
    --ssh-key-file ~/.ssh/id_ed25519.pub \
    --create-network --open-ports

  ./scripts/oracle-launch-vm-retry.sh \
    --compartment-id ocid1.compartment.oc1..aaaa \
    --ssh-key "$(cat ~/.ssh/id_ed25519.pub)" \
    --interval 120 --max-attempts 50
EOF
}

log() { printf '==> %s\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }
die() { warn "Error: $*"; exit 1; }

require_oci() {
  command -v oci >/dev/null 2>&1 || die "oci CLI not found. Use Oracle Cloud Shell or install OCI CLI."
  oci iam region list --query 'data[0].name' --raw-output >/dev/null 2>&1 || die "OCI CLI not authenticated. Run from Oracle Cloud Shell or oci setup config."
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --compartment) COMPARTMENT_NAME="$2"; shift 2 ;;
      --compartment-id) COMPARTMENT_ID="$2"; shift 2 ;;
      --name) VM_NAME="$2"; shift 2 ;;
      --ssh-key-file) SSH_KEY_FILE="$2"; shift 2 ;;
      --ssh-key) SSH_KEY="$2"; shift 2 ;;
      --image-id) IMAGE_ID="$2"; shift 2 ;;
      --subnet-id) SUBNET_ID="$2"; shift 2 ;;
      --create-network) CREATE_NETWORK=true; shift ;;
      --open-ports) OPEN_PORTS=true; shift ;;
      --interval) INTERVAL_SEC="$2"; shift 2 ;;
      --max-attempts) MAX_ATTEMPTS="$2"; shift 2 ;;
      --ocpus) OCPUS="$2"; shift 2 ;;
      --memory-gb) MEMORY_GB="$2"; shift 2 ;;
      --fallback-micro) FALLBACK_MICRO=true; shift ;;
      --dry-run) DRY_RUN=true; shift ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown option: $1 (try --help)" ;;
    esac
  done
}

load_ssh_key() {
  if [[ -n "$SSH_KEY" ]]; then
    return
  fi
  [[ -n "$SSH_KEY_FILE" ]] || die "Missing --ssh-key-file or --ssh-key"
  [[ -f "$SSH_KEY_FILE" ]] || die "SSH public key not found: $SSH_KEY_FILE"
  SSH_KEY="$(cat "$SSH_KEY_FILE")"
}

tenancy_ocid() {
  awk -F= '/^tenancy=/{gsub(/ /, "", $2); print $2; exit}' "${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}"
}

resolve_compartment_id() {
  if [[ -n "$COMPARTMENT_ID" ]]; then
    return
  fi
  [[ -n "$COMPARTMENT_NAME" ]] || die "Provide --compartment or --compartment-id"

  local root
  root="$(tenancy_ocid)"
  [[ -n "$root" ]] || die "Could not resolve tenancy OCID from OCI config"

  COMPARTMENT_ID="$(oci iam compartment list \
    --compartment-id "$root" \
    --compartment-id-in-subtree true \
    --all \
    --query "data[?name=='${COMPARTMENT_NAME}'].id | [0]" \
    --raw-output)"

  [[ -n "$COMPARTMENT_ID" && "$COMPARTMENT_ID" != "null" ]] \
    || die "Compartment not found: ${COMPARTMENT_NAME}"
  log "Compartment ${COMPARTMENT_NAME} -> ${COMPARTMENT_ID}"
}

find_existing_instance() {
  oci compute instance list \
    --compartment-id "$COMPARTMENT_ID" \
    --display-name "$VM_NAME" \
    --lifecycle-state RUNNING \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || true
}

find_ubuntu_aarch64_image() {
  if [[ -n "$IMAGE_ID" ]]; then
    return
  fi

  local tenancy root
  root="$(tenancy_ocid)"

  # Prefer Ubuntu 22.04 aarch64 compatible with A1 Flex
  IMAGE_ID="$(oci compute image list \
    --compartment-id "${root}" \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "22.04" \
    --shape "VM.Standard.A1.Flex" \
    --sort-by TIMECREATED \
    --sort-order DESC \
    --all \
    --query 'data[?contains("display-name", `aarch64`) || contains("display-name", `ARM`)].id | [0]' \
    --raw-output 2>/dev/null || true)"

  if [[ -z "$IMAGE_ID" || "$IMAGE_ID" == "null" ]]; then
    IMAGE_ID="$(oci compute image list \
      --compartment-id "${root}" \
      --operating-system "Canonical Ubuntu" \
      --operating-system-version "22.04" \
      --sort-by TIMECREATED \
      --sort-order DESC \
      --all \
      --query 'data[?contains("display-name", `22.04`) && (contains("display-name", `aarch64`) || contains("display-name", `ARM`))].id | [0]' \
      --raw-output)"
  fi

  [[ -n "$IMAGE_ID" && "$IMAGE_ID" != "null" ]] \
    || die "Could not find Ubuntu 22.04 aarch64 image. Pass --image-id manually."
  log "Image: ${IMAGE_ID}"
}

find_micro_image() {
  local root
  root="$(tenancy_ocid)"
  oci compute image list \
    --compartment-id "${root}" \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "22.04" \
    --shape "VM.Standard.E2.1.Micro" \
    --sort-by TIMECREATED \
    --sort-order DESC \
    --all \
    --query 'data[0].id' \
    --raw-output
}

find_subnet_in_compartment() {
  if [[ -n "$SUBNET_ID" ]]; then
    return
  fi

  SUBNET_ID="$(oci network subnet list \
    --compartment-id "$COMPARTMENT_ID" \
    --query 'data[?"prohibit-public-ip-on-vnic"==`false`].id | [0]' \
    --raw-output 2>/dev/null || true)"

  if [[ -n "$SUBNET_ID" && "$SUBNET_ID" != "null" ]]; then
    log "Using existing public subnet: ${SUBNET_ID}"
  fi
}

create_network_stack() {
  log "Creating VCN ${VCN_NAME} in ${COMPARTMENT_ID}"

  if $DRY_RUN; then
    warn "[dry-run] would create VCN, IGW, route table, security list, subnet"
    SUBNET_ID="ocid1.subnet.oc1.dryrun"
    return
  fi

  local vcn_id igw_id rt_id sl_id
  vcn_id="$(oci network vcn create \
    --compartment-id "$COMPARTMENT_ID" \
    --cidr-block "10.0.0.0/16" \
    --display-name "$VCN_NAME" \
    --dns-label "musicatutor" \
    --query 'data.id' \
    --raw-output)"

  igw_id="$(oci network internet-gateway create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$vcn_id" \
    --is-enabled true \
    --display-name "${VCN_NAME}-igw" \
    --query 'data.id' \
    --raw-output)"

  rt_id="$(oci network route-table create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$vcn_id" \
    --display-name "${VCN_NAME}-public-rt" \
    --route-rules "[{\"destination\":\"0.0.0.0/0\",\"destinationType\":\"CIDR_BLOCK\",\"networkEntityId\":\"${igw_id}\"}]" \
    --query 'data.id' \
    --raw-output)"

  sl_id="$(oci network security-list create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$vcn_id" \
    --display-name "${VCN_NAME}-sl" \
    --egress-rules '[{"destination":"0.0.0.0/0","protocol":"all","isStateless":false}]' \
    --ingress-rules "[{\"source\":\"0.0.0.0/0\",\"protocol\":\"6\",\"isStateless\":false,\"tcpOptions\":{\"destinationPortRange\":{\"min\":22,\"max\":22}}},{\"source\":\"0.0.0.0/0\",\"protocol\":\"6\",\"isStateless\":false,\"tcpOptions\":{\"destinationPortRange\":{\"min\":80,\"max\":80}}}]" \
    --query 'data.id' \
    --raw-output)"

  SUBNET_ID="$(oci network subnet create \
    --compartment-id "$COMPARTMENT_ID" \
    --vcn-id "$vcn_id" \
    --cidr-block "10.0.0.0/24" \
    --display-name "$SUBNET_NAME" \
    --dns-label "public" \
    --route-table-id "$rt_id" \
    --security-list-ids "[\"${sl_id}\"]" \
    --query 'data.id' \
    --raw-output)"

  log "Created subnet: ${SUBNET_ID}"
  OPEN_PORTS=true
}

ensure_network() {
  find_subnet_in_compartment
  if [[ -n "$SUBNET_ID" && "$SUBNET_ID" != "null" ]]; then
    return
  fi
  if $CREATE_NETWORK; then
    create_network_stack
    return
  fi
  die "No public subnet in compartment. Re-run with --create-network or pass --subnet-id"
}

open_ports_on_subnet_vcn() {
  $OPEN_PORTS || return 0

  if $DRY_RUN; then
    warn "[dry-run] would ensure security list allows TCP 22 and 80"
    return
  fi

  local sl_id
  sl_id="$(oci network subnet get --subnet-id "$SUBNET_ID" --query 'data."security-list-ids"[0]' --raw-output)"

  local has_80
  has_80="$(oci network security-list get --security-list-id "$sl_id" \
    --query 'data."ingress-security-rules"[?tcpOptions.destinationPortRange.min==`80`] | length(@)' \
    --raw-output 2>/dev/null || echo 0)"

  if [[ "$has_80" == "0" ]]; then
    log "Adding ingress TCP 80 to security list ${sl_id}"
    oci network security-list update \
      --security-list-id "$sl_id" \
      --ingress-security-rules "$(oci network security-list get --security-list-id "$sl_id" --query 'data."ingress-security-rules"' --raw-output | python3 -c "
import json, sys
rules = json.load(sys.stdin)
rules.append({
  'source': '0.0.0.0/0',
  'protocol': '6',
  'isStateless': False,
  'tcpOptions': {'destinationPortRange': {'min': 80, 'max': 80}}
})
print(json.dumps(rules))
")" \
      --force >/dev/null
  else
    log "Security list already allows TCP 80"
  fi
}

list_availability_domains() {
  oci iam availability-domain list --query 'data[].name' --raw-output | tr '\t' '\n'
}

launch_instance_in_ad() {
  local ad="$1"
  local shape="$2"
  local shape_config="$3"
  local image="$4"

  log "Launching ${shape} in ${ad}..."

  if $DRY_RUN; then
    warn "[dry-run] would launch ${VM_NAME} in ${ad}"
    return 0
  fi

  set +e
  local out err rc
  out="$(oci compute instance launch \
    --availability-domain "$ad" \
    --compartment-id "$COMPARTMENT_ID" \
    --display-name "$VM_NAME" \
    --shape "$shape" \
    --shape-config "$shape_config" \
    --image-id "$image" \
    --subnet-id "$SUBNET_ID" \
    --assign-public-ip true \
    --ssh-authorized-keys "$SSH_KEY" \
    --query 'data.id' \
    --raw-output 2>&1)"
  rc=$?
  set -e

  if [[ $rc -eq 0 && -n "$out" && "$out" == ocid1.instance.* ]]; then
    echo "$out"
    return 0
  fi

  err="$out"
  if echo "$err" | grep -qi 'out of capacity\|Out of host capacity\|capacity'; then
    warn "Out of capacity in ${ad}"
    return 1
  fi

  warn "Launch failed in ${ad}: ${err}"
  return 1
}

wait_for_running() {
  local instance_id="$1"
  log "Waiting for instance ${instance_id} to reach RUNNING..."

  if $DRY_RUN; then
    echo "dry-run-instance"
    return
  fi

  local i state
  for i in $(seq 1 60); do
    state="$(oci compute instance get --instance-id "$instance_id" --query 'data."lifecycle-state"' --raw-output)"
    if [[ "$state" == "RUNNING" ]]; then
      return 0
    fi
    sleep 10
  done
  die "Instance did not reach RUNNING in time"
}

get_public_ip() {
  local instance_id="$1"
  if $DRY_RUN; then
    echo "0.0.0.0"
    return
  fi

  local vnic_id
  vnic_id="$(oci compute vnic-attachment list \
    --compartment-id "$COMPARTMENT_ID" \
    --instance-id "$instance_id" \
    --query 'data[0]."vnic-id"' \
    --raw-output)"

  oci network vnic get --vnic-id "$vnic_id" --query 'data."public-ip"' --raw-output
}

retry_launch_a1() {
  local attempt=1
  local ads
  ads="$(list_availability_domains)"

  while true; do
    log "Attempt cycle ${attempt}$( [[ "$MAX_ATTEMPTS" -gt 0 ]] && echo " / ${MAX_ATTEMPTS}" )"

    while IFS= read -r ad; do
      [[ -n "$ad" ]] || continue
      local instance_id
      if instance_id="$(launch_instance_in_ad "$ad" "VM.Standard.A1.Flex" "{\"ocpus\":${OCPUS},\"memoryInGBs\":${MEMORY_GB}}" "$IMAGE_ID")"; then
        wait_for_running "$instance_id"
        local ip
        ip="$(get_public_ip "$instance_id")"
        echo ""
        log "SUCCESS"
        echo "instance_id=${instance_id}"
        echo "public_ip=${ip}"
        echo "ssh ubuntu@${ip}"
        echo ""
        echo "Next on VM:"
        echo "  git clone https://github.com/Trinhleo/guitar-ai.git ~/guitar-ai"
        echo "  cd ~/guitar-ai && ./scripts/oracle-vm-bootstrap.sh"
        return 0
      fi
      sleep 5
    done <<< "$ads"

    if [[ "$MAX_ATTEMPTS" -gt 0 && "$attempt" -ge "$MAX_ATTEMPTS" ]]; then
      return 1
    fi

    log "All ADs full — sleeping ${INTERVAL_SEC}s before retry (Ctrl+C to stop)"
    sleep "$INTERVAL_SEC"
    attempt=$((attempt + 1))
  done
}

try_fallback_micro() {
  $FALLBACK_MICRO || return 1

  warn "Trying fallback VM.Standard.E2.1.Micro (1 GB RAM — tight for Docker stack)"
  local micro_image ads ad instance_id ip
  micro_image="$(find_micro_image)"
  [[ -n "$micro_image" && "$micro_image" != "null" ]] || die "Could not find E2.1.Micro Ubuntu image"

  ads="$(list_availability_domains)"
  while IFS= read -r ad; do
    [[ -n "$ad" ]] || continue
    if instance_id="$(launch_instance_in_ad "$ad" "VM.Standard.E2.1.Micro" "{}" "$micro_image")"; then
      wait_for_running "$instance_id"
      ip="$(get_public_ip "$instance_id")"
      echo ""
      log "SUCCESS (E2.1.Micro fallback)"
      echo "instance_id=${instance_id}"
      echo "public_ip=${ip}"
      echo "ssh ubuntu@${ip}"
      return 0
    fi
  done <<< "$ads"
  return 1
}

main() {
  parse_args "$@"
  require_oci
  load_ssh_key
  resolve_compartment_id

  local existing
  existing="$(find_existing_instance)"
  if [[ -n "$existing" && "$existing" != "null" ]]; then
    local ip
    ip="$(get_public_ip "$existing")"
    log "Instance ${VM_NAME} already RUNNING"
    echo "instance_id=${existing}"
    echo "public_ip=${ip}"
    echo "ssh ubuntu@${ip}"
    exit 0
  fi

  ensure_network
  find_ubuntu_aarch64_image
  open_ports_on_subnet_vcn

  if retry_launch_a1; then
    exit 0
  fi

  if try_fallback_micro; then
    exit 0
  fi

  die "Could not launch VM. Increase --max-attempts or retry later."
}

main "$@"
