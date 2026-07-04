#!/usr/bin/env bash
# Retry applying an OCI Resource Manager stack until VM is created.
# Stops immediately when apply succeeds or instance is already RUNNING (no spam).
#
# Examples:
#   ./scripts/oracle-stack-apply-retry.sh \
#     --stack-id ocid1.ormstack.oc1.ap-singapore-1.aaaa...
#
#   ./scripts/oracle-stack-apply-retry.sh \
#     --stack-id ocid1.ormstack.oc1.ap-singapore-1.aaaa... \
#     --interval 120 --max-attempts 50
set -euo pipefail

STACK_ID=""
VM_NAME="musica-tutor-vm"
COMPARTMENT_ID=""
INTERVAL_SEC=90
MAX_ATTEMPTS=0
DRY_RUN=false
WAIT_TIMEOUT_SEC=1800

usage() {
  cat <<'EOF'
Usage: oracle-stack-apply-retry.sh --stack-id OCID [options]

Apply a saved OCI Resource Manager stack repeatedly until it succeeds.
Exits immediately when:
  - Stack apply job SUCCEEDED, or
  - Target VM is already RUNNING (idempotent — will not re-apply)

Run from Oracle Cloud Shell (OCI CLI pre-authenticated).

Required:
  --stack-id OCID           Resource Manager stack OCID (from "Save stack")

Optional:
  --vm-name NAME            Instance display name to detect (default: musica-tutor-vm)
  --compartment-id OCID     Compartment OCID (auto-read from stack if omitted)
  --interval SEC            Seconds between retries on failure (default: 90)
  --max-attempts N          Stop after N tries (0 = retry until success)
  --wait-timeout SEC        Max seconds to wait per apply job (default: 1800)
  --dry-run                 Print actions only
  --help                    Show this help

Example:
  ./scripts/oracle-stack-apply-retry.sh \
    --stack-id ocid1.ormstack.oc1.ap-singapore-1.amaaaaaaso7lw4iadqqwc7iggetnh6sj6jb5q6kojs6sim2xe7yili6xtlhq \
    --interval 90
EOF
}

log() { printf '==> %s\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }
die() { warn "Error: $*"; exit 1; }

require_oci() {
  command -v oci >/dev/null 2>&1 || die "oci CLI not found. Open Oracle Cloud Shell."
  oci iam region list --query 'data[0].name' --raw-output >/dev/null 2>&1 || die "OCI CLI not authenticated."
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stack-id) STACK_ID="$2"; shift 2 ;;
      --vm-name) VM_NAME="$2"; shift 2 ;;
      --compartment-id) COMPARTMENT_ID="$2"; shift 2 ;;
      --interval) INTERVAL_SEC="$2"; shift 2 ;;
      --max-attempts) MAX_ATTEMPTS="$2"; shift 2 ;;
      --wait-timeout) WAIT_TIMEOUT_SEC="$2"; shift 2 ;;
      --dry-run) DRY_RUN=true; shift ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown option: $1 (try --help)" ;;
    esac
  done
  [[ -n "$STACK_ID" ]] || die "Missing --stack-id"
}

load_stack_metadata() {
  if $DRY_RUN; then
    COMPARTMENT_ID="${COMPARTMENT_ID:-ocid1.compartment.oc1.dryrun}"
    return
  fi

  local meta err_file
  err_file="$(mktemp)"
  if ! meta="$(oci resource-manager stack get \
    --stack-id "$STACK_ID" \
    --query 'data.{compartment:"compartment-id",state:"lifecycle-state",name:"display-name"}' \
    2>"$err_file")"; then
    warn "OCI stack get failed:"
    sed 's/^/  /' "$err_file" >&2 || true
    rm -f "$err_file"
    die "Cannot read stack ${STACK_ID}. Fix IAM (see docs/DEPLOY_ORACLE_CI.md#iam-user-for-github-actions)."
  fi
  rm -f "$err_file"

  if [[ -z "$COMPARTMENT_ID" ]]; then
    COMPARTMENT_ID="$(echo "$meta" | python3 -c "import json,sys; print(json.load(sys.stdin)['compartment'])")"
  fi

  local stack_name stack_state
  stack_name="$(echo "$meta" | python3 -c "import json,sys; print(json.load(sys.stdin)['name'])")"
  stack_state="$(echo "$meta" | python3 -c "import json,sys; print(json.load(sys.stdin)['state'])")"
  log "Stack: ${stack_name} (${stack_state})"
  log "Compartment: ${COMPARTMENT_ID}"
}

find_running_instance() {
  if $DRY_RUN; then
    return 1
  fi

  oci compute instance list \
    --compartment-id "$COMPARTMENT_ID" \
    --display-name "$VM_NAME" \
    --lifecycle-state RUNNING \
    --query 'data[0].id' \
    --raw-output 2>/dev/null || true
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

print_success() {
  local instance_id="$1"
  local ip
  ip="$(get_public_ip "$instance_id")"
  echo ""
  log "DONE — VM is ready (no further retries)"
  echo "instance_id=${instance_id}"
  echo "public_ip=${ip}"
  echo "ssh ubuntu@${ip}"
  echo ""
  echo "Next:"
  echo "  ssh ubuntu@${ip}"
  echo "  git clone https://github.com/Trinhleo/guitar-ai.git ~/guitar-ai"
  echo "  cd ~/guitar-ai && ./scripts/oracle-vm-bootstrap.sh"
}

check_already_running() {
  local instance_id
  instance_id="$(find_running_instance)"
  if [[ -n "$instance_id" && "$instance_id" != "null" ]]; then
    log "Instance ${VM_NAME} already RUNNING — skipping apply (no spam)"
    print_success "$instance_id"
    exit 0
  fi
}

last_apply_job_state() {
  oci resource-manager job list \
    --stack-id "$STACK_ID" \
    --sort-by TIMECREATED \
    --sort-order DESC \
    --limit 1 \
    --query 'data[0]."lifecycle-state"' \
    --raw-output 2>/dev/null || true
}

job_failed_out_of_capacity() {
  local job_id="$1"
  local logs
  logs="$(oci resource-manager job get-job-logs-content --job-id "$job_id" --query 'data.content' --raw-output 2>/dev/null || true)"
  echo "$logs" | grep -qi 'out of capacity\|Out of host capacity\|capacity' && return 0
  return 1
}

apply_stack_once() {
  if $DRY_RUN; then
    warn "[dry-run] would create APPLY job for stack ${STACK_ID}"
    return 0
  fi

  local job_id err_file
  err_file="$(mktemp)"
  if ! job_id="$(oci resource-manager job create-apply-job \
    --stack-id "$STACK_ID" \
    --execution-plan-strategy AUTO_APPROVED \
    --query 'data.id' \
    --raw-output 2>"$err_file")"; then
    warn "Apply job create failed:"
    sed 's/^/  /' "$err_file" >&2 || true
    rm -f "$err_file"
    return 1
  fi
  rm -f "$err_file"

  log "Apply job created: ${job_id}"

  set +e
  oci resource-manager job wait-for-job \
    --job-id "$job_id" \
    --wait-for-state SUCCEEDED \
    --max-wait-seconds "$WAIT_TIMEOUT_SEC" >/dev/null 2>&1
  local wait_rc=$?
  set -e

  if [[ $wait_rc -eq 0 ]]; then
    return 0
  fi

  local state
  state="$(oci resource-manager job get --job-id "$job_id" --query 'data."lifecycle-state"' --raw-output)"
  if job_failed_out_of_capacity "$job_id"; then
    warn "Apply failed: out of capacity (${state})"
  else
    warn "Apply failed (${state}) — check job logs in Console → Resource Manager → Jobs"
    oci resource-manager job get --job-id "$job_id" --query 'data."lifecycle-state-details"' --raw-output 2>/dev/null || true
  fi
  return 1
}

main() {
  parse_args "$@"
  require_oci
  load_stack_metadata

  # Idempotent: VM already exists → stop immediately
  check_already_running

  local attempt=1
  while true; do
    log "Apply attempt ${attempt}$( [[ "$MAX_ATTEMPTS" -gt 0 ]] && echo " / ${MAX_ATTEMPTS}" )"

    if apply_stack_once; then
      # Apply succeeded — verify instance is RUNNING then exit (no more loops)
      sleep 10
      local instance_id
      for _ in $(seq 1 12); do
        instance_id="$(find_running_instance)"
        if [[ -n "$instance_id" && "$instance_id" != "null" ]]; then
          print_success "$instance_id"
          exit 0
        fi
        sleep 10
      done
      log "Stack apply succeeded but instance not RUNNING yet — check Oracle Console"
      exit 0
    fi

    # Re-check in case another process created the VM
    instance_id="$(find_running_instance)"
    if [[ -n "$instance_id" && "$instance_id" != "null" ]]; then
      log "Instance appeared while retrying — stopping"
      print_success "$instance_id"
      exit 0
    fi

    if [[ "$MAX_ATTEMPTS" -gt 0 && "$attempt" -ge "$MAX_ATTEMPTS" ]]; then
      die "Max attempts (${MAX_ATTEMPTS}) reached. Retry later or increase --max-attempts."
    fi

    log "Sleeping ${INTERVAL_SEC}s before next apply (Ctrl+C to stop)"
    sleep "$INTERVAL_SEC"
    attempt=$((attempt + 1))
  done
}

main "$@"
