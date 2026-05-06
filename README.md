# disable-omarchy-repo

A small Bash script that disables the [Omarchy](https://omarchy.org) pacman repository on an Arch Linux system, so that future `pacman -Syu` runs sync only `core`, `extra`, and `multilib`.

## Why

Omarchy ships its own pacman repo (`pkgs.omarchy.org`) that re-packages or pins certain tools (e.g. `claude-code`, `1password-beta`, `walker`, etc.). This is convenient on a fresh Omarchy install, but the repo sometimes lags behind upstream Arch or the AUR, and pinned versions can hold back or conflict with system updates.

If you used Omarchy as an installer/bootstrap but want to maintain your machine as a standard Arch system from then on, disabling the repo is the simplest path.

## What the script does

- Backs up `/etc/pacman.conf` to `/etc/pacman.conf.bak.YYYYMMDD-HHMMSS` before any change.
- Comments out the entire `[omarchy]` repo block in `/etc/pacman.conf` — the section header, `SigLevel`, and `Server` lines — by structure, not hardcoded line numbers.
- Idempotent: re-running after the repo is already disabled is a no-op.
- Preserves correct file ownership and permissions (`root:root`, `0644`).
- Prints the resulting block so you can verify the change.

## Requirements

- Arch Linux (or an Arch-based system using `/etc/pacman.conf`)
- `bash`, `awk`, `sudo` (all standard)
- Sudo privileges

## Usage

### One-liner

```sh
curl -fsSL https://raw.githubusercontent.com/DanielCoffey1/disable-omarchy-repo/main/disable-omarchy-repo.sh | bash
```

You'll be prompted for your sudo password during the run.

> **Piping a remote script straight into `bash` is a trust decision.** If you'd rather inspect it first, use the manual install below.

### Manual

```sh
git clone https://github.com/DanielCoffey1/disable-omarchy-repo.git
cd disable-omarchy-repo
chmod +x disable-omarchy-repo.sh
./disable-omarchy-repo.sh
```

After it finishes, refresh your databases:

```sh
sudo pacman -Syu
```

The omarchy database will no longer sync.

## What happens to packages already installed from Omarchy

Disabling the repo does **not** uninstall anything. Packages previously installed from `omarchy/*` remain on disk but become "foreign" from pacman's perspective — pacman keeps them but won't update them.

To see which packages on your system came from the omarchy repo before disabling it, run:

```sh
pacman -Sl omarchy | awk '$4=="[installed]"{print $2}'
```

You generally have three options for each:

1. **Replace with the AUR version** — e.g. `yay -S claude-code` will swap the omarchy build for the AUR build, after which it tracks AUR upstream.
2. **Replace with an official-repo version** if one exists.
3. **Leave it alone** — the package will simply stop receiving updates. Fine for omarchy-only packages like `omarchy-keyring`, `omarchy-nvim`, `omarchy-walker`, the `elephant-*` family, etc.

## Reverting

A timestamped backup is saved every time the script runs. To restore:

```sh
sudo cp /etc/pacman.conf.bak.YYYYMMDD-HHMMSS /etc/pacman.conf
sudo pacman -Sy
```

## License

MIT
