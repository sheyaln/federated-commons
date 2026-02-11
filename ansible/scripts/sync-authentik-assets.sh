#!/usr/bin/env bash
#
# Sync Authentik branding assets + application icons to the Authentik host.
# Intended to be invoked via ../sync-assets.sh (wrapper), but can be used directly:
#   ./sync-authentik-assets.sh <host_or_ip> [--delete] [--restart]
#
# Notes:
# - Reads ssh user default from ../inventory.ini ([authentik-prod] group)
# - Uses ssh as 'ubuntu' (or inventory ansible_user) and sudo on the remote host when needed
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INVENTORY_FILE="${INVENTORY_FILE:-$BASE_DIR/inventory.ini}"

AUTHENTIK_DIR="${AUTHENTIK_DIR:-/opt/authentik}"

LOCAL_CUSTOM_ASSETS_DIR="$BASE_DIR/roles/authentik/authentik/files/custom-assets"
LOCAL_APP_ICONS_DIR="$BASE_DIR/roles/authentik/authentik/files/application-icons"

COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_BLUE=$'\033[0;34m'
COLOR_RESET=$'\033[0m'

info() { echo "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"; }
ok() { echo "${COLOR_GREEN}[OK]${COLOR_RESET} $*"; }
err() { echo "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2; }

usage() {
  cat <<'USAGE'
Usage:
  sync-authentik-assets.sh <host_or_ip> [--delete] [--restart]

Options:
  --delete     Delete remote files that are not present locally (dangerous).
  --restart    Restart Authentik containers after syncing.

Environment:
  INVENTORY_FILE   Path to inventory.ini (default: ../inventory.ini)
  AUTHENTIK_DIR    Remote Authentik dir (default: /opt/authentik)
  SSH_USER         Override ssh username (default: from inventory or ubuntu)
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

TARGET_HOST="$1"
shift

DO_DELETE="false"
DO_RESTART="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete) DO_DELETE="true" ;;
    --restart) DO_RESTART="true" ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 2 ;;
  esac
  shift
done

if [[ ! -f "$INVENTORY_FILE" ]]; then
  err "Inventory file not found: $INVENTORY_FILE"
  exit 1
fi

if [[ ! -d "$LOCAL_CUSTOM_ASSETS_DIR" ]]; then
  err "Local custom-assets dir not found: $LOCAL_CUSTOM_ASSETS_DIR"
  exit 1
fi

if [[ ! -d "$LOCAL_APP_ICONS_DIR" ]]; then
  err "Local application-icons dir not found: $LOCAL_APP_ICONS_DIR"
  exit 1
fi

read_inventory_for_host() {
  # Prints: "<ssh_user>"
  # If not found, prints empty.
  awk -v host="$TARGET_HOST" '
    BEGIN { in_group=0 }
    /^\[authentik-prod\]$/ { in_group=1; next }
    /^\[/ { in_group=0 }
    in_group && $0 !~ /^[[:space:]]*#/ && NF > 0 {
      if ($1 == host) {
        user=""
        for (i=2; i<=NF; i++) {
          if ($i ~ /^ansible_user=/) { sub(/^ansible_user=/, "", $i); user=$i }
        }
        printf "%s\n", user
        exit
      }
    }
  ' "$INVENTORY_FILE"
}

INV_LINE="$(read_inventory_for_host || true)"
INV_USER="$(printf "%s" "$INV_LINE")"

SSH_USER="${SSH_USER:-${INV_USER:-ubuntu}}"

SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new)

REMOTE="${SSH_USER}@${TARGET_HOST}"
REMOTE_CUSTOM_ASSETS_DIR="${AUTHENTIK_DIR}/custom-assets"
REMOTE_APP_ICONS_DIR="${AUTHENTIK_DIR}/application-icons"

RSYNC_SSH=(ssh "${SSH_OPTS[@]}")
RSYNC_ARGS=(-az --checksum --delete-delay --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r --no-perms --no-owner --no-group)
if [[ "$DO_DELETE" == "true" ]]; then
  RSYNC_ARGS+=(--delete)
fi

info "Ensuring remote directories exist on ${TARGET_HOST}..."
ssh "${SSH_OPTS[@]}" "$REMOTE" "sudo mkdir -p '$REMOTE_CUSTOM_ASSETS_DIR' '$REMOTE_APP_ICONS_DIR'"
ok "Remote directories are ready."

info "Syncing custom-assets -> ${REMOTE_CUSTOM_ASSETS_DIR}"
rsync "${RSYNC_ARGS[@]}" -e "${RSYNC_SSH[*]}" --rsync-path="sudo rsync" \
  "${LOCAL_CUSTOM_ASSETS_DIR}/" "${REMOTE}:${REMOTE_CUSTOM_ASSETS_DIR}/"
ok "custom-assets synced."

info "Syncing application-icons -> ${REMOTE_APP_ICONS_DIR}"
rsync "${RSYNC_ARGS[@]}" -e "${RSYNC_SSH[*]}" --rsync-path="sudo rsync" \
  "${LOCAL_APP_ICONS_DIR}/" "${REMOTE}:${REMOTE_APP_ICONS_DIR}/"
ok "application-icons synced."

if [[ "$DO_RESTART" == "true" ]]; then
  info "Restarting Authentik containers (server + worker)..."
  # Try without sudo first (user may have docker access), then fallback to sudo.
  if ! ssh "${SSH_OPTS[@]}" "$REMOTE" "cd '$AUTHENTIK_DIR' && docker compose restart server worker"; then
    ssh "${SSH_OPTS[@]}" "$REMOTE" "cd '$AUTHENTIK_DIR' && sudo docker compose restart server worker"
  fi
  ok "Restart requested."
fi

info "Running a quick local healthcheck on the host..."
if ssh "${SSH_OPTS[@]}" "$REMOTE" "curl -fsS http://127.0.0.1:9000/api/v3/root/config/ >/dev/null"; then
  ok "Authentik API healthcheck OK."
else
  err "Healthcheck failed (could be transient). You can check logs with: ssh ${SSH_USER}@${TARGET_HOST} 'cd $AUTHENTIK_DIR && docker compose logs --tail=200 server'"
  exit 1
fi

ok "Done."


