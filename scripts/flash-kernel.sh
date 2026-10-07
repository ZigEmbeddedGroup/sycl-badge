#!/usr/bin/env bash
# Build the OS kernel and flash it onto a badge over USB.
#
#   scripts/flash-kernel.sh
#   BADGE_TTY=/dev/ttyACM1 scripts/flash-kernel.sh
#
# The steps: build with the Zig that mise.toml pins, unmount ./mnt, ask the
# running OS to `reboot bootsel` over its USB console, mount the RP2350 boot
# ROM drive on ./mnt, copy the kernel in, wait for the badge to come back, and
# mount its cart store on ./mnt again. Mounts use sudo and `sync`.
#
# A kernel from before the `reboot bootsel` command ignores the request. The
# script then tells you which buttons to press and waits.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/badge-lib.sh"

tty=${BADGE_TTY:-/dev/ttyACM0}
kernel="$BADGE_ROOT/zig-out/firmware/sycl-os-kernel.uf2"

cd "$BADGE_ROOT"
log "building the kernel"
mise exec -- zig build
[ -f "$kernel" ] || die "the build did not produce $kernel"

unmount_mnt

if [ -w "$tty" ]; then
  log "sending 'reboot bootsel' to the OS console on $tty"
  stty -F "$tty" raw -echo
  # A bare return first, in case a half-typed line is sitting in the console.
  printf '\rreboot bootsel\r' > "$tty"
else
  log "$tty is not writable, so the OS cannot be asked to reboot"
fi

if ! wait_for_label RP2350 10 > /dev/null; then
  log "no boot ROM drive yet. On the back of the badge: hold RESET and BOOT_SEL,"
  log "release RESET, then release BOOT_SEL."
  wait_for_label RP2350 120 > /dev/null || die "the RP2350 drive did not appear"
fi
mount_label RP2350 5 || die "the RP2350 drive vanished before it could be mounted"

log "copying $(basename "$kernel")"
# The boot ROM resets as soon as the last block lands, and the drive goes away
# under us. A late error from cp, sync or umount is the normal outcome.
cp "$kernel" "$BADGE_MNT/" || log "cp reported an error at the end; the reset causes this"
sync || true
sudo umount "$BADGE_MNT" 2>/dev/null || sudo umount -l "$BADGE_MNT" 2>/dev/null || true

log "waiting for the badge to reboot"
wait_for_label_gone RP2350 30 || log "the RP2350 drive is still present; the copy may not have finished"
mount_cart_store 60
log "the new kernel is running and its cart store is on $BADGE_MNT"
