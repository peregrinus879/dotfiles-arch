# Strix Halo ROCm Prep for Local Models

This guide documents a validated Arch Linux path for preparing an AMD Strix Halo machine for ROCm-backed local model workloads.

The sequence below produced a working setup on an AMD Ryzen AI Max+ 395 system with Radeon 8060S Graphics and `128 GiB` of unified memory. Ollama, `gemma4:31b`, and OpenCode are layered on top of that machine preparation.

This is hardware-specific reference material, not baseline setup required by `dotfiles-arch`.

## Validated Platform

- CPU: `AMD Ryzen AI Max+ 395`
- GPU: `Radeon 8060S Graphics`
- platform family: `Strix Halo`
- unified memory: `128 GiB`
- page size: `4096`
- ROCm target: `gfx1151`

Validated memory values for this host:

- BIOS VRAM carve-out: `512MB`
- Linux-visible RAM after BIOS tuning: about `124 GiB`
- TTM/GTT shared GPU memory target: `96 GiB`
- `ttm.pages_limit` on a `4096` byte page-size system: `25165824`

Do not assume those exact numbers fit every Strix Halo machine. Lower-memory systems need a different TTM/GTT target even though the overall pattern stays the same: keep BIOS VRAM small and increase shared GPU memory instead.

## Support Boundary

- AMD's current ROCm Ryzen compatibility matrix lists `AMD Ryzen AI Max+ 395` under Linux support for ROCm `7.2.1`
- AMD's Strix Halo optimization guidance also notes that Arch Linux includes the required kernel fixes in native packaging
- this document is still a verified Arch-host guide, not a statement of official AMD Arch support for every ROCm component or package combination

## Outcome

- restore normal Linux-visible system RAM after BIOS tuning
- expose enough shared GPU memory for local LLM workloads
- prepare the machine for ROCm-backed local model workloads on Arch Linux
- optionally run Ollama with ROCm on Arch Linux
- optionally run `gemma4:31b` on the local GPU
- optionally expose the local model in OpenCode

## Why This Works

- Strix Halo uses unified memory, so a large BIOS VRAM carve-out permanently reduces Linux-visible RAM without giving the same kind of benefit that a discrete GPU gets from dedicated VRAM
- the working pattern on this host was small BIOS VRAM plus large TTM/GTT shared GPU memory
- the TTM/GTT limit is the practical lever for making more shared memory available to local AI workloads
- on this Limine plus mkinitcpio UKI system, the TTM setting did not apply until the UKI was rebuilt with `mkinitcpio -P`

## Host Preparation

Follow this sequence in the validated order.

This guide assumes Arch is already installed on the host. For the underlying dual-SSD install, see `INSTALL.md`.

For Ollama, use the official upstream installer. An Arch `ollama` package path was not required on this host.

### 1. Set BIOS VRAM low

Set the BIOS GPU memory option to:

```text
512MB
```

This exact value was validated on the `AMD Ryzen AI Max+ 395` / `Radeon 8060S Graphics` / `128 GiB` host.

Do not use large BIOS VRAM presets for this workflow.

### 2. Boot Arch and verify the memory layout

```bash
free -h
```

Expected on the validated host:

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

Expected intermediate state on the validated host before the TTM retune:

- `VRAM total: 0.50 GiB`
- `GTT total: 62.47 GiB`

### 3. Raise TTM/GTT to 96 GiB

On a `4096` byte page-size system, the working value on the validated host was:

```text
25165824
```

That value corresponds to:

```text
96 GiB * 1024^3 / 4096 = 25165824 pages
```

Create `/etc/modprobe.d/ttm.conf` with:

```text
options ttm pages_limit=25165824
```

This exact `96 GiB` target is specific to the `128 GiB` validated host. Recalculate the target if your Strix Halo machine has less total memory.

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

On this verified Arch system, the TTM setting did not apply until the UKI was rebuilt with `mkinitcpio -P`. If your boot flow is different, rebuild the equivalent initramfs or boot artifacts before rebooting.

### 5. Verify the TTM retune after reboot

```bash
printf 'TTM_PAGES_LIMIT=%s\n' "$(cat /sys/module/ttm/parameters/pages_limit)"
awk -v p="$(cat /sys/module/ttm/parameters/pages_limit)" -v s="$(getconf PAGE_SIZE)" 'BEGIN {
  printf "TTM limit: %.2f GiB\n", (p*s)/(1024*1024*1024)
}'
```

Expected on the validated host:

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

Expected host-ready state on the validated host:

- `VRAM total: 0.50 GiB`
- `GTT total: 96.00 GiB`

## Optional Model Stack

Use the sequence below to reproduce the validated local-model stack on top of the prepared host.

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

If `rocminfo` is not already on `PATH`, call it by full path:

```bash
rocminfo | grep -E 'Marketing Name|Name:.*gfx'
```

Expected on the validated host:

- an AMD marketing name
- `Name: gfx1151`

### 8. Install Ollama from upstream

Use the official upstream installer:

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

This installed:

- `/usr/local/bin/ollama`
- the systemd service
- the upstream ROCm payload

If `ollama` is not already on `PATH`, call it by full path from `/usr/local/bin/ollama`.

### 9. Grant GPU access

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

### 10. Verify Ollama

```bash
sudo systemctl status ollama --no-pager
systemctl cat ollama
ollama -v
```

Expected on the validated host:

```text
ollama version is 0.20.0
```

Verify ROCm detection:

```bash
journalctl -u ollama -b | grep -iE 'rocm|hip|gfx|gpu|amdgpu'
```

Expected on the validated host:

- `library=ROCm`
- `compute=gfx1151`
- `available="96.3 GiB"`

On this host:

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

Expected on the validated host:

- `gemma4:31b`
- `100% GPU`
- context length `262144`

### 13. Optional OpenCode integration

Install OpenCode on Arch:

```bash
sudo pacman -Syu opencode
```

OpenCode's Ollama provider uses the local OpenAI-compatible endpoint:

```text
http://127.0.0.1:11434/v1
```

Add a provider block to `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      },
      "models": {
        "gemma4:31b": {
          "name": "gemma4:31b"
        }
      }
    }
  }
}
```

If you want Gemma to become the global default model in OpenCode, also add:

```json
"model": "ollama/gemma4:31b"
```

If you do not want Ollama to become the default, keep your existing top-level default model pointed at OpenAI if that is your current setup. If you do not already have a top-level default, leave `model` unset and select the Ollama model when needed.

Quick-setup alternative:

```bash
ollama launch opencode --config --model gemma4:31b
```

On this host, that command auto-added the Ollama provider.

That quick path works, but it can also set the top-level OpenCode model to `ollama/gemma4:31b` automatically.

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

If you installed OpenCode, you can also verify it with:

```bash
opencode --version
```

## Validated Outcome

The following values are specific to the validated `AMD Ryzen AI Max+ 395` / `Radeon 8060S Graphics` / `128 GiB` host:

- BIOS VRAM carve-out: `512MB`
- Linux-visible RAM: about `124 GiB`
- TTM/GTT shared GPU memory: `96 GiB`
- `VRAM total: 0.50 GiB`
- `GTT total: 96.00 GiB`
- `TTM limit: 96.00 GiB`
- ROCm target: `gfx1151`
- `rocminfo` reports `gfx1151`
- Ollama version: `0.20.0`
- Ollama backend: `library=ROCm`
- Ollama available GPU memory: about `96.3 GiB`
- Model: `gemma4:31b`
- `ollama ps`: `100% GPU`
