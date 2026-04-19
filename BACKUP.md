# Backup

Pre-install capture of everything that does not survive a clean Arch install on a headless hub. Run this before `INSTALL.md`.

## Purpose

Reinstalling Arch on the primary SSD wipes the filesystem, which discards:

- keys that do not live in a password manager
- per-project AI harness state and memory
- system configuration under `/etc` outside any managed repo
- enabled unit names, installed package sets, and group memberships
- personal files in `$HOME` that are not tracked in a Git remote
- application state such as Syncthing device identity and Tailscale node state

This runbook captures the subset worth preserving, verifies the backup, and hands off to `INSTALL.md`.

## Scope

In scope:

- one-off pre-install capture on a headless hub
- pull-from-hub pattern with the client machine as the backup target

Out of scope:

- tracked repository content that already lives on GitHub
- regenerable state: `~/.cache`, `~/.local/share/nvim/{lazy,mason}`, `~/.config/opencode/node_modules`
- ephemeral state: Claude Code sessions, shell snapshots, browser tabs
- recurring backup routines (see `vault/SELF-HOSTING.md` for the vault-side auto-commit story)

## Prerequisites

- Hub reachable from the client over Tailscale (MagicDNS name or Tailscale IP).
- Client has free space on the backup target. Default target is `~/Downloads/backup/`. Large media collections may need an external USB drive instead.
- Password manager available on the client for crypto and inventory artifacts.

Set the variables used throughout this guide on the **client** machine:

```bash
HUB=<host>                     # Tailscale MagicDNS name or IP
BACKUP=~/Downloads/backup
FPR=<YOUR-GPG-FINGERPRINT>     # look up with: ssh "$HUB" 'gpg --list-secret-keys --keyid-format=long'

mkdir -p "$BACKUP"
chmod 700 "$BACKUP"
```

## 1. Pre-flight

### 1.1 Confirm client-to-hub SSH works

```bash
ssh "$HUB" 'hostname; uname -a'
```

### 1.2 Verify every repo is clean and pushed

Any uncommitted, stashed, or unpushed work will be lost unless committed and pushed before wipe. Run this on the **hub**:

```bash
ssh "$HUB" bash <<'EOF'
for d in ~/projects/repos/dotfiles/* ~/projects/repos/templates/* ~/vault; do
  [ -d "$d/.git" ] || continue
  printf '=== %s ===\n' "$d"
  git -C "$d" status --short --branch
  echo '--- unpushed ---'
  git -C "$d" log --oneline @{u}.. 2>/dev/null
  echo '--- stashes ---'
  git -C "$d" stash list
  echo
done
EOF
```

Expected output per repo: branch `## main...origin/main`, no files listed, no unpushed commits, no stashes.

If any repo shows pending work, commit and push before continuing.

## 2. Crypto material

Stream GPG secret material over SSH stdout so it never materializes on the hub's disk.

### 2.1 GPG keys

```bash
ssh "$HUB" "gpg --export-secret-keys --armor $FPR" > "$BACKUP/vault-backup-private.asc"
ssh "$HUB" "gpg --export --armor $FPR"             > "$BACKUP/vault-backup-public.asc"
ssh "$HUB" 'gpg --export-ownertrust'               > "$BACKUP/vault-backup-ownertrust.txt"
scp "$HUB:.gnupg/openpgp-revocs.d/$FPR.rev" "$BACKUP/vault-backup-revocation.asc"
```

File names match `vault/SELF-HOSTING.md` §3.4 so the §7 recovery path works without renames.

### 2.2 git-crypt symmetric key

```bash
ssh "$HUB" 'cd ~/vault && git-crypt export-key -' > "$BACKUP/vault-git-crypt.key"
```

### 2.3 SSH keys

List what exists on the hub, then copy the identity and deploy keys:

```bash
ssh "$HUB" 'ls ~/.ssh/'

scp "$HUB:.ssh/vault-deploy-key"     "$BACKUP/"
scp "$HUB:.ssh/vault-deploy-key.pub" "$BACKUP/"
scp "$HUB:.ssh/id_ed25519"           "$BACKUP/"
scp "$HUB:.ssh/id_ed25519.pub"       "$BACKUP/"
```

Substitute the actual identity filename if it is not `id_ed25519`.

### 2.4 Tighten permissions

```bash
chmod 600 "$BACKUP"/*
```

### 2.5 Cross-references

- `vault/SELF-HOSTING.md` §3.4 covers the same export commands from the hub side.
- `vault/SELF-HOSTING.md` §7 covers the reverse flow after reinstall (fresh clone + git-crypt unlock + gcrypt reconfig).

## 3. AI harness state

Not tracked in `dotfiles-ai` by design. Back up what carries value across sessions and drop the rest.

### 3.1 Claude Code per-project memory

```bash
rsync -aHAX "$HUB:.claude/projects/" "$BACKUP/claude/projects/"
```

Includes each project's `memory/` subdir and any pinned plans. Large `sessions/` history inside each project is included too; prune after restore if not wanted.

### 3.2 Claude Code global files

```bash
rsync -aHAX \
  --include='memory/***' \
  --include='tasks/***' \
  --include='plans/***' \
  --exclude='*' \
  "$HUB:.claude/" "$BACKUP/claude/"
```

Skip `sessions/`, `shell-snapshots/`, `cache/`, `downloads/`, `paste-cache/`, `backups/`, `file-history/` as ephemeral.

### 3.3 Auth state

Not backed up. Re-login after install:

- Claude Code: `/login` on first launch
- OpenCode: `opencode auth login`
- GitHub CLI: `gh auth login`

## 4. System configuration outside `$HOME`

### 4.1 `/etc` captures

```bash
mkdir -p "$BACKUP/etc"
ssh "$HUB" 'sudo tar -cf - \
  /etc/modprobe.d \
  /etc/systemd/system \
  /etc/fstab \
  /etc/hosts \
  /etc/pacman.conf \
  /etc/sudoers.d 2>/dev/null' \
  | tar -xf - -C "$BACKUP/etc/"
```

`/etc/fstab` is captured for reference when rebuilding the secondary-SSD mount entry in `INSTALL.md`, not for literal restore.

### 4.2 ROCm and Ollama plumbing

`/etc/modprobe.d/ttm.conf` is captured above. The canonical recipe to regenerate it after reinstall lives in `STRIX-HALO-ROCM.md` §3. Do not restore it blindly on a different host.

The upstream Ollama installer recreates `/etc/systemd/system/ollama.service` during its own installation step (`STRIX-HALO-ROCM.md` §8). No need to restore that unit file manually.

## 5. Inventory snapshots

Record the shape of the current system so reinstall can reach parity without restoring binaries.

```bash
mkdir -p "$BACKUP/inventory"

ssh "$HUB" 'pacman -Qqe'                                 > "$BACKUP/inventory/packages-explicit.txt"
ssh "$HUB" 'pacman -Qqm'                                 > "$BACKUP/inventory/packages-aur.txt"
ssh "$HUB" 'systemctl list-unit-files --state=enabled'   > "$BACKUP/inventory/enabled-system-units.txt"
ssh "$HUB" 'systemctl --user list-unit-files --state=enabled' > "$BACKUP/inventory/enabled-user-units.txt"
ssh "$HUB" 'id'                                          > "$BACKUP/inventory/groups.txt"
ssh "$HUB" 'crontab -l 2>/dev/null || true'              > "$BACKUP/inventory/crontab.txt"
ssh "$HUB" 'lsblk -o NAME,SIZE,MODEL,MOUNTPOINT,FSTYPE,UUID' > "$BACKUP/inventory/lsblk.txt"
ssh "$HUB" 'findmnt --real'                              > "$BACKUP/inventory/mounts.txt"
```

Use these as reference during and after reinstall. `packages-explicit.txt` is a superset of the baseline from `README.md`; install the baseline first, then reinstate extras from the diff.

## 6. Personal files

Probe footprints first so the copy step sizes correctly:

```bash
ssh "$HUB" 'du -sh ~/Documents ~/Downloads ~/Pictures ~/Videos ~/Music ~/Desktop 2>/dev/null'
```

For each populated directory, rsync to the client:

```bash
rsync -aHAX --info=progress2 "$HUB:Documents/" "$BACKUP/Documents/"
rsync -aHAX --info=progress2 "$HUB:Pictures/"  "$BACKUP/Pictures/"
rsync -aHAX --info=progress2 "$HUB:Videos/"    "$BACKUP/Videos/"
rsync -aHAX --info=progress2 "$HUB:Music/"     "$BACKUP/Music/"
```

Selective hidden captures worth checking:

```bash
ssh "$HUB" 'ls ~/.local/bin 2>/dev/null; du -sh ~/.local/share 2>/dev/null'
```

Copy `~/.local/bin/` if it holds custom scripts. `~/.local/share/` is app-specific; inspect before copying to avoid dragging in regenerable caches.

## 7. Application state

### 7.1 Syncthing

Device ID is derived from the Syncthing key. Losing the config means every paired device has to accept a new ID.

```bash
rsync -aHAX "$HUB:.local/state/syncthing/" "$BACKUP/syncthing-state/" 2>/dev/null \
  || rsync -aHAX "$HUB:.config/syncthing/" "$BACKUP/syncthing-state/"
```

Restore to the same path after install, before starting the `syncthing@<user>` service.

### 7.2 Tailscale

State at `/var/lib/tailscale/` is not backed up. Re-auth with `sudo tailscale up` after install; a new node appears in the admin console. Optionally remove the old node from the admin console once the new one is authenticated.

### 7.3 Obsidian

`~/vault/.obsidian/` is tracked inside the vault repo with Syncthing and git-crypt. Recovered by following `vault/SELF-HOSTING.md` §7 after install. No separate backup needed.

## 8. Verify

### 8.1 GPG export round-trip

Import into an isolated keyring to confirm the file is intact and usable:

```bash
mkdir -p /tmp/gpg-verify && chmod 700 /tmp/gpg-verify
GNUPGHOME=/tmp/gpg-verify gpg --import "$BACKUP/vault-backup-private.asc"
GNUPGHOME=/tmp/gpg-verify gpg --import-ownertrust "$BACKUP/vault-backup-ownertrust.txt"
GNUPGHOME=/tmp/gpg-verify gpg --list-secret-keys --keyid-format=long
rm -rf /tmp/gpg-verify
```

The listing must show the expected fingerprint as a secret key.

### 8.2 Personal-files spot check

Pick any subdirectory and compare size against the source:

```bash
ssh "$HUB" 'du -sh ~/Documents'
du -sh "$BACKUP/Documents"
```

### 8.3 Manifest

```bash
( cd "$BACKUP" && find . -type f | sort > MANIFEST.txt )
wc -l "$BACKUP/MANIFEST.txt"
```

Attach the manifest alongside the backup bundle.

## 9. Store and hand off

### 9.1 Password manager

Store the crypto files and inventory text files as attachments:

- `vault-backup-private.asc`
- `vault-backup-public.asc`
- `vault-backup-ownertrust.txt`
- `vault-backup-revocation.asc`
- `vault-git-crypt.key`
- `vault-deploy-key`, `vault-deploy-key.pub`
- `id_ed25519`, `id_ed25519.pub`
- `inventory/*.txt`

### 9.2 Encrypted bundle for bulk data

Personal files and AI harness memory are too large for most password managers. Wrap into a single encrypted archive:

```bash
tar -C "$BACKUP" -czf - . \
  | gpg --symmetric --cipher-algo AES256 -o ~/pre-install-backup.tgz.gpg
```

Store `~/pre-install-backup.tgz.gpg` on an external drive, a second machine, or cloud storage. The passphrase must be recorded separately in the password manager.

### 9.3 Clean up the cleartext workspace

```bash
rm -rf "$BACKUP"
```

`shred` is unreliable on copy-on-write filesystems such as btrfs and on SSD-backed ext4 with discard, so plain `rm` plus a TRIM pass is the realistic guarantee. Keep the encrypted bundle; discard the cleartext.

### 9.4 Hand off

Proceed to `INSTALL.md`. Keep the backup bundle and password manager at hand during the install because:

- archinstall prompts for the user's authorized SSH keys during user creation
- first-boot Tailscale setup needs your login on the auth URL
- vault recovery per `vault/SELF-HOSTING.md` §7 needs both GPG and git-crypt keys

## References

- `INSTALL.md` - the install runbook this backup precedes
- `STRIX-HALO-ROCM.md` §3, §8 - canonical recipe for ROCm and Ollama plumbing after install
- `vault/SELF-HOSTING.md` §3.4 - hub-side export of GPG and git-crypt material
- `vault/SELF-HOSTING.md` §7 - fresh-clone recovery of the encrypted vault
