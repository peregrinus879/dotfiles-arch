# Install

End-to-end install runbook for a headless Arch host with a dual-SSD layout: one primary for the system, one secondary for data.

Run `BACKUP.md` before this guide.

## Purpose

This doc covers the bare-metal install and storage setup that sits beneath the dotfiles in `README.md`. It assumes a machine with two NVMe slots where the primary boots Arch and the secondary is mounted as a data volume. Ownership of the dotfiles layer and ROCm plumbing stays in their own docs; this guide links out rather than duplicates.

## Scope

In scope:

- archinstall on the primary SSD with btrfs defaults, no encryption, and zram swap
- first-boot access on a headless box, including Tailscale bootstrap
- secondary SSD setup post-install: btrfs, single subvolume, fstab, mount
- verification at the system layer

Out of scope:

- dotfiles stow (`README.md`)
- ROCm and Ollama prep (`STRIX-HALO-ROCM.md`)
- encrypted vault recovery (`vault/SELF-HOSTING.md` §7)
- backup policy (`BACKUP.md`)
- non-storage BIOS tuning, for example the VRAM carve-out in `STRIX-HALO-ROCM.md` §1 if applicable

## Hardware layout

| Slot | Role | Filesystem | Mounts |
|---|---|---|---|
| Primary | Arch system | btrfs (archinstall default subvolumes) | `/`, `/home`, `/var/log`, `/var/cache/pacman/pkg`, `/boot` as FAT32 ESP |
| Secondary | Data volume | btrfs, single subvolume `@backup` | `/srv/backup` |

The secondary holds user data such as documents and media. A Nextcloud or similar service can later publish from it. This guide does not install Nextcloud.

## Pre-flight

### 1. Complete the pre-install backup

Finish every step in `BACKUP.md`. Keep the encrypted backup bundle and password manager reachable during the install; first boot needs SSH keys, GPG keys, and the git-crypt key to rebuild repos and restore the vault.

### 2. Prepare the install media

- Download the Arch ISO dated `2026-04-01` (or newer) from the Arch mirrors.
- Verify the signature against the Arch signing keys.
- Write the ISO to a USB stick.

### 3. Swap the physical disks

Power off, remove the current primary from its slot, install the new primary in the same slot, and move the previous primary into the secondary slot.

Power on and enter the firmware setup to confirm:

- Both NVMe devices are detected.
- Boot order lists the USB installer above the internal disks.

## archinstall on the primary

Boot the installer, log in as `root`, and launch `archinstall`.

Make the following selections; accept defaults for anything not called out.

### 1. Disk configuration

- Open the disk configuration menu.
- Target: **primary** device only. Leave the secondary untouched in this step; it is configured post-install to reduce the chance of wiping the wrong drive.
- Layout: accept archinstall's default or best-effort partition layout for the primary.
- Filesystem: `btrfs`.
- Subvolume layout: accept archinstall's default btrfs subvolume layout.
- Compression: enable btrfs compression if prompted; default is `zstd`.
- Encryption: skip.

### 2. Bootloader

Select `limine` as the bootloader with a mkinitcpio-generated UKI. archinstall writes the UKI to `/boot/EFI/Linux/arch-linux.efi`.

### 3. Swap

Enable zram. This is the archinstall default and matches the pre-wipe behavior.

### 4. Locale and network

- Locale, timezone, and keymap: set to match your environment.
- Hostname: pick a short hostname (used by local DNS and Tailscale MagicDNS).
- Network: `copy ISO network configuration` is fine if the installer is online.

### 5. User

- Create a regular user with a password.
- When archinstall prompts for authorized SSH keys for that user, paste the **public** key of your client machine. This seeds `~/.ssh/authorized_keys` so you can SSH in on first boot without physical console access.
- Make the user a sudoer.

### 6. Additional packages

Add at least `openssh` and `tailscale` to the install set so first-boot access works without another pacman round-trip.

### 7. Services

Enable `sshd` (and optionally `tailscaled`) so they start on first boot.

### 8. Install

Run the install. Reboot into the fresh system when complete. Remove the USB stick.

## First-boot access

### 1. Rotate the client-side host key cache

The new install generated fresh OpenSSH host keys. Before reconnecting from the client, purge stale entries:

```bash
ssh-keygen -R <hostname>
ssh-keygen -R <hostname>.<tailnet>.ts.net
ssh-keygen -R <tailscale-ip>
ssh-keygen -R <lan-ip>
```

Skip the lines that do not apply.

### 2. Reach the hub

The hub is not on Tailscale yet. Use one of these paths for the first connection:

- **LAN SSH**: connect to the DHCP-assigned LAN IP using the key you pasted into archinstall. Find the LAN IP from your router's DHCP lease table, or briefly attach a monitor and keyboard to run `ip addr`.
- **Physical console**: monitor plus keyboard on the hub.

### 3. Bring up Tailscale

If Tailscale was not installed during archinstall:

```bash
sudo pacman -S tailscale
```

Enable and start the daemon, then authenticate:

```bash
sudo systemctl enable --now tailscaled
sudo tailscale up
```

Open the printed URL on any browser, approve the node, and verify:

```bash
tailscale status
```

From this point, the hub is reachable over Tailscale by MagicDNS name or Tailscale IP. Remove the old node entry in the Tailscale admin console if it no longer applies.

### 4. Optional: Tailscale SSH

If you prefer Tailscale SSH over raw OpenSSH auth:

```bash
sudo tailscale up --ssh
```

## Dotfiles, ROCm, and vault

Follow these in order after first-boot access is stable:

1. Install and stow the dotfiles per `README.md` (`dotfiles-arch` baseline) and `dotfiles-ai` if applicable.
2. Recreate the local git identity file at `~/.config/git/config.local` per `README.md` §4.
3. If the host needs ROCm and local-model prep, follow `STRIX-HALO-ROCM.md` end to end.
4. Restore the encrypted vault per `vault/SELF-HOSTING.md` §7 using the GPG key and git-crypt key from the backup bundle.
5. From your client machine, push AI harness per-project memory back to the hub: `rsync -aHAX ~/Downloads/backup/claude/projects/ "$HUB":.claude/projects/`.

## Secondary SSD setup

Run these after the primary is stable and you are logged in over Tailscale. All commands run on the hub.

### 1. Identify the secondary

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINT,FSTYPE
```

Pick the device that matches the secondary slot by size or serial. Confirm it is **not** the primary before the next step. The placeholder below is `/dev/nvmeXn1`.

### 2. Wipe existing signatures

```bash
SECONDARY=/dev/nvmeXn1
sudo wipefs -a "$SECONDARY"
```

### 3. Partition

Create a single GPT partition spanning the whole device:

```bash
sudo sgdisk --zap-all "$SECONDARY"
sudo sgdisk --new=1:0:0 --typecode=1:8300 --change-name=1:secondary "$SECONDARY"
sudo partprobe "$SECONDARY"
```

The data partition is now at `${SECONDARY}p1`.

### 4. Create the filesystem

```bash
SECONDARY_PART="${SECONDARY}p1"
sudo mkfs.btrfs -L secondary "$SECONDARY_PART"
```

### 5. Create the `@backup` subvolume

Mount the top-level filesystem, create the subvolume, then unmount:

```bash
sudo mkdir -p /mnt/tmp-secondary
sudo mount "$SECONDARY_PART" /mnt/tmp-secondary
sudo btrfs subvolume create /mnt/tmp-secondary/@backup
sudo umount /mnt/tmp-secondary
sudo rmdir /mnt/tmp-secondary
```

### 6. Add the fstab entry

Look up the filesystem UUID:

```bash
sudo blkid "$SECONDARY_PART"
```

Copy the `UUID=...` value. Append this line to `/etc/fstab` (substitute the UUID):

```text
UUID=<secondary-uuid>  /srv/backup  btrfs  rw,noatime,ssd,discard=async,space_cache=v2,compress=zstd:3,subvol=/@backup,nofail,x-systemd.device-timeout=10  0 0
```

`nofail` and `x-systemd.device-timeout=10` keep the headless boot resilient if the secondary fails or is absent.

### 7. Mount

```bash
sudo mkdir -p /srv/backup
sudo systemctl daemon-reload
sudo mount /srv/backup
```

### 8. Ownership

Make the user own the mount so applications run without root:

```bash
sudo chown "$USER":"$USER" /srv/backup
```

## Verify

System-level checks after both disks are configured:

```bash
# Primary is rooted on btrfs with the expected subvolumes
findmnt /
findmnt /home

# Secondary is mounted at /srv/backup on btrfs with the expected options
findmnt /srv/backup

# Both are visible and healthy
lsblk -o NAME,SIZE,MOUNTPOINT,FSTYPE,UUID

# Filesystems report no errors
sudo btrfs filesystem show
sudo btrfs filesystem usage /
sudo btrfs filesystem usage /srv/backup

# Reboot survives
sudo systemctl reboot
# then, after reconnect:
findmnt /srv/backup
```

Dotfiles and ROCm have their own verification sections; follow them in `README.md` and `STRIX-HALO-ROCM.md` respectively.

## Future enhancements

- **Nextcloud on the secondary**. Publish `/srv/backup` subdirectories through Nextcloud so documents and media are reachable from any device on the Tailscale mesh. Create child subvolumes under `@backup` (for example `@backup/docs`, `@backup/gallery`) before Nextcloud starts writing, so per-dataset snapshots and `btrfs send | btrfs receive` are clean.
- **Per-dataset snapshots**. Introduce `snapper` or `btrbk` against `@backup` once the dataset shape stabilizes.
- **Off-host replication**. Use `btrfs send | btrfs receive` over SSH to mirror `@backup` snapshots to a second machine on the Tailscale mesh.
- **Optional FDE retrofit for the secondary**. Add LUKS2 with a keyfile on the primary so the secondary unlocks headlessly at boot, without reinstalling the primary.
- **Primary FDE**. If you later want full-disk encryption on the primary, reinstall with LUKS2 plus TPM2 auto-unlock (`systemd-cryptenroll`). Plan the reinstall the same way as this guide and keep `BACKUP.md` in the loop.

## References

- `BACKUP.md` - pre-install capture, runs before this guide
- `README.md` - dotfiles stow, verification, local git identity
- `STRIX-HALO-ROCM.md` - BIOS tuning, TTM retune, ROCm, Ollama, and OpenCode provider
- `vault/SELF-HOSTING.md` §7 - fresh-clone recovery of the encrypted vault
- `AGENTS.md` - canonical repo context and maintainer checklist
