#!/usr/bin/env bash
# Copy carts onto the badge's cart store.
#
#   scripts/load-cart.sh rust/target/fill.uf2
#   scripts/load-cart.sh rust/target/*.uf2
#
# Mounts the SYCLBADGE drive on ./mnt with sudo and `sync` unless it is already
# mounted that way, then copies the files in one at a time. The badge shows a
# progress bar while the OS writes each cart to flash, then lists it on the
# cart screen.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/badge-lib.sh"

[ $# -ge 1 ] || die "usage: $(basename "$0") <cart.uf2>..."

# Check every argument before touching the badge, so a typo in the last one
# does not leave the copy half done.
for cart in "$@"; do
  [ -f "$cart" ] || die "no such file: $cart"
  case "$cart" in
    *.uf2) ;;
    *) die "the badge only loads .uf2 files: $cart" ;;
  esac
done

mount_cart_store 30
for cart in "$@"; do
  log "copying $(basename "$cart") to $BADGE_MNT"
  cp "$cart" "$BADGE_MNT/"
  sync
done
log "done: $# cart(s) copied"
