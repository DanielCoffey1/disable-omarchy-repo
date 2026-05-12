#!/usr/bin/env bash
set -euo pipefail

CONF=/etc/pacman.conf

if [[ ! -f $CONF ]]; then
  echo "Error: $CONF not found" >&2
  exit 1
fi

if ! grep -qE '^\[omarchy\]' "$CONF"; then
  echo "Omarchy repo not active in $CONF (already disabled or never present)."
  exit 0
fi

BACKUP="$CONF.bak.$(date +%Y%m%d-%H%M%S)"
echo "Backing up $CONF -> $BACKUP"
sudo cp -a "$CONF" "$BACKUP"

# Comment out the [omarchy] block: from the `[omarchy]` header through its
# associated lines, stopping at the next [section] header or a blank line.
awk '
  /^\[omarchy\]/        { in_block = 1; print "#" $0; next }
  in_block && /^\[/     { in_block = 0; print; next }
  in_block && /^[[:space:]]*$/ { in_block = 0; print; next }
  in_block              { print "#" $0; next }
                        { print }
' "$CONF" | sudo tee "$CONF.new" >/dev/null

sudo install -m 644 -o root -g root "$CONF.new" "$CONF"
sudo rm -f "$CONF.new"

echo
echo "Done. Resulting omarchy section:"
grep -n -E '^#?\[omarchy\]|^#?SigLevel|^#?Server.*omarchy' "$CONF" || true
echo
if grep -q 'stable-mirror\.omarchy\.org' /etc/pacman.d/mirrorlist 2>/dev/null; then
  echo "Note: /etc/pacman.d/mirrorlist still uses Omarchy's Arch mirror."
  echo "Run './switch-to-arch-mirrors.sh' if you want regular Arch mirrors."
  echo
fi
echo "Run 'sudo pacman -Syu' to refresh databases without omarchy."
