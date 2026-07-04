#!/usr/bin/env bash
# Verify the OCI API user (GitHub Actions) can read and apply a Resource Manager stack.
# Run in Oracle Cloud Shell after configuring a test profile (see docs/DEPLOY_ORACLE_CI.md).
#
# Example:
#   export OCI_CONFIG_FILE=~/.oci/github-user.conf
#   export OCI_STACK_ID=ocid1.ormstack.oc1.ap-singapore-1.aaaa...
#   ./scripts/verify-oci-github-user.sh
set -euo pipefail

STACK_ID="${OCI_STACK_ID:-}"
CONFIG="${OCI_CONFIG_FILE:-${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}}"

usage() {
  cat <<EOF
Usage: OCI_STACK_ID=ocid1.ormstack... [OCI_CONFIG_FILE=~/.oci/github-user.conf] $0

Tests stack read using the OCI CLI profile (same credentials as GitHub Secrets).
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

[[ -n "$STACK_ID" ]] || { usage; die "Set OCI_STACK_ID"; }
[[ -f "$CONFIG" ]] || die "Config not found: $CONFIG"

echo "==> Using config: $CONFIG"
echo "==> Stack: $STACK_ID"
echo ""

echo "Current profile user:"
oci --config-file "$CONFIG" iam user get --user-id "$(awk -F= '/^user=/{print $2}' "$CONFIG")" \
  --query 'data.{name:name,ocid:id}' 2>/dev/null || die "Cannot read user — check API key in config"

echo ""
echo "Stack metadata:"
if ! oci --config-file "$CONFIG" resource-manager stack get \
  --stack-id "$STACK_ID" \
  --query 'data.{name:"display-name",compartment:"compartment-id",state:"lifecycle-state"}'; then
  echo ""
  die "Stack read FAILED — user lacks permission or stack OCID/region is wrong"
fi

comp_id="$(oci --config-file "$CONFIG" resource-manager stack get \
  --stack-id "$STACK_ID" --query 'data."compartment-id"' --raw-output)"
comp_name="$(oci --config-file "$CONFIG" iam compartment get --compartment-id "$comp_id" \
  --query 'data.name' --raw-output 2>/dev/null || echo unknown)"

echo ""
echo "Stack compartment: ${comp_name} (${comp_id})"
echo ""
echo "OK — this API user can read the stack. GitHub Actions should pass stack get."
echo "If GitHub still fails, confirm OCI_USER_OCID matches this user and secrets are in Environment production."
