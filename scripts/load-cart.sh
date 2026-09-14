#!/usr/bin/env bash
# Copy a cart onto the badge's cart store.
#
#   scripts/load-cart.sh rust/target/fill.uf2
#
# Mounts the SYCLBADGE drive on ./mnt with sudo and `sync` unless it is already
# mounted that way, then copies the file in. The badge shows a progress bar
# while the OS writes the cart to flash, then lists it on the cart screen.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/badge-lib.sh"

[ $# -eq 1 ] || die "usage: $(basename "$0") <cart.uf2>"
cart=$1
[ -f "$cart" ] || die "no such file: $cart"
case "$cart" in
  *.uf2) ;;
  *) die "the badge only loads .uf2 files: $cart" ;;
esac

mount_cart_store 30
log "copying $(basename "$cart") to $BADGE_MNT"
cp "$cart" "$BADGE_MNT/"
sync
log "done"
