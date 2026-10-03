# Shared helpers for the badge scripts. Source this file; do not run it.
#
# Both scripts mount a badge drive on ./mnt at the repo root. The mounts go
# through sudo and use `sync`, so every write reaches the device before `cp`
# returns and nothing is left in a buffer when the drive disappears. The uid
# and gid options make the mounting user own the files, so the copy itself
# needs no sudo.

BADGE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BADGE_MNT="$BADGE_ROOT/mnt"
BADGE_MOUNT_OPTS="sync,uid=$(id -u),gid=$(id -g)"

log() { printf '>> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Print the block device behind /dev/disk/by-label/<label>, waiting up to
# <seconds> for it to appear.
wait_for_label() {
  local label=$1 seconds=$2 dev i
  for ((i = 0; i < seconds * 2; i++)); do
    if dev=$(readlink -f "/dev/disk/by-label/$label" 2>/dev/null) && [ -b "$dev" ]; then
      printf '%s\n' "$dev"
      return 0
    fi
    sleep 0.5
  done
  return 1
}

# Wait up to <seconds> for the drive labelled <label> to go away.
wait_for_label_gone() {
  local label=$1 seconds=$2 i
  for ((i = 0; i < seconds * 2; i++)); do
    [ -e "/dev/disk/by-label/$label" ] || return 0
    sleep 0.5
  done
  return 1
}

mnt_is_mounted() { mountpoint -q "$BADGE_MNT"; }

# The label of whatever is mounted on ./mnt, or nothing.
mnt_label() {
  local src
  src=$(findmnt -n -o SOURCE "$BADGE_MNT" 2>/dev/null) || return 0
  lsblk -no LABEL "$src" 2>/dev/null || true
}

mnt_has_sync() {
  findmnt -n -o OPTIONS "$BADGE_MNT" 2>/dev/null | tr ',' '\n' | grep -qx sync
}

unmount_mnt() {
  if mnt_is_mounted; then
    log "unmounting $BADGE_MNT"
    sudo umount "$BADGE_MNT" 2>/dev/null || sudo umount -l "$BADGE_MNT"
  fi
}

# Mount the drive labelled <label> on ./mnt, waiting up to <seconds> for it.
mount_label() {
  local label=$1 seconds=$2 dev i
  dev=$(wait_for_label "$label" "$seconds") || return 1
  mkdir -p "$BADGE_MNT"
  log "mounting $dev ($label) on $BADGE_MNT with sync"
  sudo mount -o "$BADGE_MOUNT_OPTS" "$dev" "$BADGE_MNT"
}

# Make sure the OS's cart store (label SYCLBADGE) is mounted on ./mnt with
# sync, waiting up to <seconds> for the badge to present it.
mount_cart_store() {
  local seconds=$1
  if mnt_is_mounted; then
    if [ "$(mnt_label)" = SYCLBADGE ] && mnt_has_sync; then
      return 0
    fi
    log "$BADGE_MNT holds another drive or lacks sync; remounting"
    unmount_mnt
  fi
  mount_label SYCLBADGE "$seconds" ||
    die "no SYCLBADGE drive appeared in $seconds s; is the badge plugged in and running the OS?"
}
