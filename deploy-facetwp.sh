#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_KEY="${SCRIPT_DIR}/ssh_key.txt"
LOCAL_SRC="${SCRIPT_DIR}/facetwp/"

# Load .env if present
ENV_FILE="${SCRIPT_DIR}/.env"
if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck source=/dev/null
  set -a; source "${ENV_FILE}"; set +a
fi
# SYNC_FROM: optional path to rsync facetwp from before deploying

# ─── Targets ──────────────────────────────────────────────────────────────────
# Format: "label|user|host|port|remote_path"
TARGETS=(
  "rda-dev|master_bhxfntusar|139.59.151.100|22|/home/master/applications/dev/public_html/wp-content/plugins/facetwp/"
  # "rda-staging|master_xyz|1.2.3.4|22|/home/master/applications/STAGING_SLUG/public_html/wp-content/plugins/facetwp/"
  # "rda-prod|master_xyz|5.6.7.8|22|/home/master/applications/PROD_SLUG/public_html/wp-content/plugins/facetwp/"
  "liverty|master_pyebeyzefp|45.77.51.3|22|/home/master/applications/livertylive/public_html/wp-content/plugins/facetwp/"
  "wpi|master_pyebeyzefp|45.77.51.3|22|/home/master/applications/wpi/public_html/wp-content/plugins/facetwp/"
  "scp|master_pyebeyzefp|45.77.51.3|22|/home/master/applications/scp/public_html/wp-content/plugins/facetwp/"
  "htqct|master_pyebeyzefp|45.77.51.3|22|/home/master/applications/ctlive/public_html/wp-content/plugins/facetwp/"
  "tappc|master_jjcupqskgb|108.61.251.71|22|/home/master/applications/nchzfukjqn/public_html/wp-content/plugins/facetwp/"
  "mmc|master_jpykwhusdp|165.22.26.161|22|/home/master/applications/ruxtuchpar/public_html/wp-content/plugins/facetwp/"
)

# ─── Helpers ──────────────────────────────────────────────────────────────────
sync_local() {
  if [[ -z "${SYNC_FROM:-}" ]]; then
    return
  fi
  if [[ ! -d "${SYNC_FROM}" ]]; then
    echo "Error: SYNC_FROM directory not found: ${SYNC_FROM}" >&2
    exit 1
  fi
  echo "→ Syncing from ${SYNC_FROM}/ to ${LOCAL_SRC}"
  rsync -av --delete "${SYNC_FROM}/" "${LOCAL_SRC}"
  echo "✓ Local sync done"
  echo ""
}


usage() {
  echo "Usage: $0 [target|all]"
  echo ""
  echo "Targets:"
  for entry in "${TARGETS[@]}"; do
    label="${entry%%|*}"
    echo "  ${label}"
  done
  echo "  all"
  exit 1
}

deploy() {
  local label="$1" user="$2" host="$3" port="$4" remote_path="$5"
  echo ""
  echo "→ [${label}] ${user}@${host}:${remote_path}"
  rsync -avz --delete \
    -e "ssh -p ${port} -i ${SSH_KEY} -o StrictHostKeyChecking=no" \
    "${LOCAL_SRC}" \
    "${user}@${host}:${remote_path}"
  echo "✓ [${label}] done"
}

run_target() {
  local name="$1"
  local matched=0
  for entry in "${TARGETS[@]}"; do
    IFS='|' read -r label user host port remote_path <<< "${entry}"
    if [[ "${label}" == "${name}" ]]; then
      deploy "${label}" "${user}" "${host}" "${port}" "${remote_path}"
      matched=1
      break
    fi
  done
  if [[ "${matched}" -eq 0 ]]; then
    echo "Error: unknown target '${name}'" >&2
    usage
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
  usage
fi

sync_local

ARG="${1}"

if [[ "${ARG}" == "all" ]]; then
  for entry in "${TARGETS[@]}"; do
    IFS='|' read -r label user host port remote_path <<< "${entry}"
    deploy "${label}" "${user}" "${host}" "${port}" "${remote_path}"
  done
else
  for target in "$@"; do
    run_target "${target}"
  done
fi

echo ""
echo "=== Deploy complete ==="
