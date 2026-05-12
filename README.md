# disable-omarchy-repo

A small set of Bash scripts for moving an [Omarchy](https://omarchy.org) install closer to a normal Arch Linux package setup.

- `disable-omarchy-repo.sh` disables the Omarchy pacman repository in `/etc/pacman.conf`.
- `switch-to-arch-mirrors.sh` replaces Omarchy's delayed Arch mirror with regular Arch mirrors using `reflector`.

## Why

Omarchy has two separate package sources worth understanding:

1. An Omarchy pacman repo (`pkgs.omarchy.org`) that re-packages or pins certain tools (e.g. `claude-code`, `1password-beta`, `walker`, etc.).
2. An Omarchy Arch mirror (`stable-mirror.omarchy.org`) that serves `core`, `extra`, and `multilib`, but may intentionally trail latest Arch packages.

If you used Omarchy as an installer/bootstrap but want to maintain your machine as a standard Arch system from then on, disable the Omarchy repo and switch away from the Omarchy Arch mirror.

## What the scripts do

### `disable-omarchy-repo.sh`

- Backs up `/etc/pacman.conf` to `/etc/pacman.conf.bak.YYYYMMDD-HHMMSS` before any change.
- Comments out the entire `[omarchy]` repo block in `/etc/pacman.conf` — the section header, `SigLevel`, and `Server` lines — by structure, not hardcoded line numbers.
- Idempotent: re-running after the repo is already disabled is a no-op.
- Preserves correct file ownership and permissions (`root:root`, `0644`).
- Prints the resulting block so you can verify the change.

### `switch-to-arch-mirrors.sh`

- Backs up `/etc/pacman.d/mirrorlist` to `/etc/pacman.d/mirrorlist.bak.YYYYMMDD-HHMMSS` before any change.
- Uses `reflector` to write regular Arch HTTPS mirrors.
- Defaults to US mirrors, the 20 most recently synced mirrors, sorted by rate.
- Accepts optional flags for country, mirror count, and sorting.
- Prints the resulting mirrorlist header and first mirror entries so you can verify the change.

## Requirements

- Arch Linux (or an Arch-based system using `/etc/pacman.conf`)
- `bash`, `awk`, `sudo` (all standard)
- `reflector` if you want to run `switch-to-arch-mirrors.sh`
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

If you also want regular Arch mirrors instead of Omarchy's Arch mirror:

```sh
chmod +x switch-to-arch-mirrors.sh
./switch-to-arch-mirrors.sh
```

Then force-refresh package databases and update:

```sh
sudo pacman -Syyu
```

The Omarchy database will no longer sync, and `core`, `extra`, and `multilib` will come from normal Arch mirrors.

### Mirror script options

```sh
./switch-to-arch-mirrors.sh --country US --latest 20 --sort rate
```

Supported options:

- `--country <name>`: country passed to `reflector` (default: `US`)
- `--latest <count>`: number of recently synced mirrors to consider (default: `20`)
- `--sort <mode>`: `reflector` sort mode (default: `rate`)
- `-h`, `--help`: show usage

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

Timestamped backups are saved every time the scripts make a change.

To restore `/etc/pacman.conf`:

```sh
sudo cp /etc/pacman.conf.bak.YYYYMMDD-HHMMSS /etc/pacman.conf
sudo pacman -Sy
```

To restore `/etc/pacman.d/mirrorlist`:

```sh
sudo cp /etc/pacman.d/mirrorlist.bak.YYYYMMDD-HHMMSS /etc/pacman.d/mirrorlist
sudo pacman -Syy
```

## License

MIT
