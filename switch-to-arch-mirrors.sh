#!/usr/bin/env bash
set -euo pipefail

MIRRORLIST=/etc/pacman.d/mirrorlist
COUNTRY=US
LATEST=20
SORT=rate

usage() {
  cat <<'EOF'
Usage:
  ./switch-to-arch-mirrors.sh [options]

Options:
  --country <name>  Country passed to reflector (default: US)
  --latest <count>  Number of recently synced mirrors to consider (default: 20)
  --sort <mode>     Reflector sort mode (default: rate)
  -h, --help        Show this help

Example:
  ./switch-to-arch-mirrors.sh --country US --latest 20 --sort rate
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --country)
      COUNTRY=${2:-}
      shift 2
      ;;
    --latest)
      LATEST=${2:-}
      shift 2
      ;;
    --sort)
      SORT=${2:-}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f $MIRRORLIST ]]; then
  echo "Error: $MIRRORLIST not found" >&2
  exit 1
fi

if [[ -z $COUNTRY || -z $LATEST || -z $SORT ]]; then
  echo "Error: --country, --latest, and --sort require non-empty values" >&2
  exit 1
fi

if ! command -v reflector >/dev/null 2>&1; then
  echo "Error: reflector is not installed." >&2
  echo "Install it with: sudo pacman -S reflector" >&2
  exit 1
fi

BACKUP="$MIRRORLIST.bak.$(date +%Y%m%d-%H%M%S)"
echo "Backing up $MIRRORLIST -> $BACKUP"
sudo cp -a "$MIRRORLIST" "$BACKUP"

echo "Writing regular Arch mirrors to $MIRRORLIST"
sudo reflector \
  --country "$COUNTRY" \
  --latest "$LATEST" \
  --protocol https \
  --sort "$SORT" \
  --save "$MIRRORLIST"

echo
echo "Done. First mirror entries:"
grep -nE '^(#|Server = )' "$MIRRORLIST" | head -20
echo
echo "Run 'sudo pacman -Syyu' to force-refresh databases from the new mirrors."
