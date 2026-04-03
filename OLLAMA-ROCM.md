# Ollama ROCm

This runbook documents a verified Arch Linux setup path for ROCm-backed Ollama running `gemma4:31b` on an AMD shared-memory system.

It is a hardware-specific reference, not baseline setup required by `dotfiles-arch`.

## Goal

- restore normal Linux-visible system RAM after BIOS tuning
- expose enough shared GPU memory for local LLM workloads
- run Ollama with ROCm on Arch Linux
- run `gemma4:31b` on the local GPU

## Final Verified State

- BIOS VRAM carve-out: `512MB`
- Linux-visible RAM: about `124 GiB`
- TTM/GTT shared GPU memory: `96 GiB`
- ROCm target: `gfx1151`
- Ollama version: `0.20.0`
- Ollama backend: `library=ROCm`
- Ollama available GPU memory: about `96.3 GiB`
- Model: `gemma4:31b`
- `ollama ps`: `100% GPU`

## Key Findings

- A large BIOS VRAM carve-out was the wrong lever for this workload.
- The working pattern was small BIOS VRAM plus large TTM/GTT shared GPU memory.
- The working Ollama install path was the official upstream installer.
- On this Limine plus mkinitcpio UKI system, the TTM setting did not apply until the UKI was rebuilt with `mkinitcpio -P`.

## Verified Sequence

This sequence keeps the verified working path, but removes the earlier Arch `ollama` package detour because it was not required for the final setup.

### 1. Set BIOS VRAM low

Set the BIOS GPU memory option to:

```text
512MB
```

Do not use large BIOS VRAM presets for this workflow.

### 2. Boot Arch and verify the memory layout

```bash
free -h
```

Expected:

- Linux sees roughly the full machine memory again, about `124 GiB`

Check AMDGPU sysfs memory values:

```bash
for d in /sys/class/drm/card*/device; do
  printf '\n== %s ==\n' "$d"
  for f in mem_info_vram_total mem_info_vram_used mem_info_gtt_total mem_info_gtt_used; do
    [ -r "$d/$f" ] && printf '%s: %s\n' "$f" "$(cat "$d/$f")"
  done
done
```

Convert to GiB:

```bash
for d in /sys/class/drm/card*/device; do
  [ -r "$d/mem_info_vram_total" ] || continue
  v=$(cat "$d/mem_info_vram_total")
  g=$(cat "$d/mem_info_gtt_total")
  printf '\n== %s ==\n' "$d"
  awk -v v="$v" -v g="$g" 'BEGIN {
    printf "VRAM total: %.2f GiB\n", v/(1024*1024*1024)
    printf "GTT total: %.2f GiB\n", g/(1024*1024*1024)
  }'
done
```

Expected intermediate state before the TTM retune:

- `VRAM total: 0.50 GiB`
- `GTT total: 62.47 GiB`

### 3. Raise TTM/GTT to 96 GiB

On a `4096` byte page-size system, the working value was:

```text
25165824
```

Create `/etc/modprobe.d/ttm.conf` with:

```text
options ttm pages_limit=25165824
```

### 4. Rebuild the boot image

This machine used Limine plus a mkinitcpio UKI. The active preset pointed to:

```text
/boot/EFI/Linux/arch-linux.efi
```

Rebuild the image:

```bash
sudo mkinitcpio -P
```

Then reboot.

### 5. Verify the TTM retune after reboot

```bash
printf 'TTM_PAGES_LIMIT=%s\n' "$(cat /sys/module/ttm/parameters/pages_limit)"
awk -v p="$(cat /sys/module/ttm/parameters/pages_limit)" -v s="$(getconf PAGE_SIZE)" 'BEGIN {
  printf "TTM limit: %.2f GiB\n", (p*s)/(1024*1024*1024)
}'
```

Expected:

- `TTM_PAGES_LIMIT=25165824`
- `TTM limit: 96.00 GiB`

Re-check GPU memory:

```bash
for d in /sys/class/drm/card*/device; do
  [ -r "$d/mem_info_vram_total" ] || continue
  v=$(cat "$d/mem_info_vram_total")
  g=$(cat "$d/mem_info_gtt_total")
  printf '\n== %s ==\n' "$d"
  awk -v v="$v" -v g="$g" 'BEGIN {
    printf "VRAM total: %.2f GiB\n", v/(1024*1024*1024)
    printf "GTT total: %.2f GiB\n", g/(1024*1024*1024)
  }'
done
```

Expected final state:

- `VRAM total: 0.50 GiB`
- `GTT total: 96.00 GiB`

### 6. Install `rocminfo`

Install the ROCm info tool from Arch so you can verify GPU detection:

```bash
sudo pacman -Syu rocminfo
```

The binary is installed at:

```text
/opt/rocm/bin/rocminfo
```

### 7. Verify ROCm detection

If `rocminfo` is not already on `PATH`, call it by full path. Then verify:

```bash
rocminfo | grep -E 'Marketing Name|Name:.*gfx'
```

Expected:

- an AMD marketing name
- `Name: gfx1151`

### 8. Install the latest Ollama from upstream

The verified install path was the official upstream installer:

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

This installed:

- `/usr/local/bin/ollama`
- the systemd service
- the upstream ROCm payload

If `ollama` is not already on `PATH`, call it by full path from `/usr/local/bin/ollama`.

### 9. Give the service and user GPU access

Add both the `ollama` service user and your login user to the `render` and `video` groups:

```bash
sudo usermod -aG render,video ollama
sudo usermod -aG render,video "$USER"
```

Verify:

```bash
id ollama
getent group render
getent group video
```

Restart Ollama so the service picks up the new group membership:

```bash
sudo systemctl restart ollama
```

Your current shell may need a new login before your own group membership is refreshed.

### 10. Verify upstream Ollama

```bash
sudo systemctl status ollama --no-pager
systemctl cat ollama
ollama -v
```

Expected working version:

```text
ollama version is 0.20.0
```

Verify ROCm detection:

```bash
journalctl -u ollama -b | grep -iE 'rocm|hip|gfx|gpu|amdgpu'
```

Expected:

- `library=ROCm`
- `compute=gfx1151`
- `available="96.3 GiB"`

In the verified session:

- the installer created `/etc/systemd/system/ollama.service`
- the service ran `/usr/local/bin/ollama serve`

### 11. Pull and run Gemma 4

```bash
ollama pull gemma4:31b
ollama run gemma4:31b
```

Exit the interactive chat with `Ctrl+D`, or `Ctrl+C` if needed.

### 12. Verify the API and loaded model

List installed models:

```bash
curl http://127.0.0.1:11434/api/tags
```

One-shot API chat test:

```bash
curl http://127.0.0.1:11434/api/chat -d '{
  "model": "gemma4:31b",
  "messages": [{"role": "user", "content": "Hello"}],
  "stream": false
}'
```

Check runtime placement:

```bash
ollama ps
```

Expected:

- `gemma4:31b`
- `100% GPU`
- context length `262144`

## Optional OpenCode Integration

If you want to expose the local model in OpenCode later, add an Ollama provider block to your OpenCode config and keep your top-level default model pointed at OpenAI if you do not want Ollama to become the default.

The session command that auto-added the Ollama provider was:

```bash
ollama launch opencode --config --model gemma4:31b
```

That works, but it also sets the top-level OpenCode model to:

```json
"model": "ollama/gemma4:31b"
```

Use that only if you want Gemma to become the global default model in OpenCode.

## Quick Verification

```bash
free -h
rocminfo | grep -E 'Marketing Name|Name:.*gfx'
ollama -v
sudo systemctl status ollama --no-pager
journalctl -u ollama -b | grep -iE 'rocm|hip|gfx|gpu|amdgpu'
curl http://127.0.0.1:11434/api/tags
ollama ps
```

## Known-Good Indicators

- `VRAM total: 0.50 GiB`
- `GTT total: 96.00 GiB`
- `TTM limit: 96.00 GiB`
- `rocminfo` reports `gfx1151`
- `ollama version is 0.20.0`
- Ollama logs show `library=ROCm`
- `ollama ps` shows `gemma4:31b` on `100% GPU`
