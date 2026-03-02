# my-evremap

> [!NOTE]
> 🤖 This repo was vibe coded with [Claude Sonnet 4.6](https://www.anthropic.com/claude) via [OpenCode](https://opencode.ai).

Personal [evremap](https://github.com/brentdurksen/evremap) config and installer for [@brentdurksen](https://github.com/brentdurksen).

```bash
curl -sSL e.clip.rip | sudo bash
```

## What this installs

1. The `evremap` binary for your architecture (`x86_64` or `aarch64`), downloaded from [brentdurksen/evremap](https://github.com/brentdurksen/evremap/releases) releases → `/usr/bin/evremap`
2. `evremap.toml` (this repo) → `/etc/evremap.toml`
3. `evremap.service` (this repo) → `/etc/systemd/system/evremap.service`, enabled and started

Re-running the install script will overwrite all of the above with the latest versions.

## Build from source

To build the binary from source instead of downloading a pre-built one, clone both repos side by side and run:

```bash
git clone https://github.com/brentdurksen/evremap.git
git clone https://github.com/brentdurksen/my-evremap.git
cd my-evremap
sudo ./install.sh --build
```

## Config

`evremap.toml` is designed for use with `--all-keyboards` — no `device_name` needed.

### CAPSLOCK as Hyper

| Action | Output |
|--------|--------|
| Tap CAPSLOCK | `Esc` |
| Hold CAPSLOCK | `Ctrl+Alt+Meta` (Hyper) |

### Hyper navigation

| Chord | Output | Effect |
|-------|--------|--------|
| `Hyper+J` | `Ctrl+Down` | Scroll down by paragraph |
| `Hyper+K` | `Ctrl+Up` | Scroll up by paragraph |

### Hyper task manager shortcuts

Map to `Win+1` through `Win+10` for switching pinned taskbar/dock entries.

| Chord | Output |
|-------|--------|
| `Hyper+F` | `Win+1` |
| `Hyper+1` | `Win+2` |
| `Hyper+Enter` | `Win+3` |
| `Hyper+V` | `Win+4` |
| `Hyper+N` | `Win+5` |
| `Hyper+A` | `Win+6` |
| `Hyper+E` | `Win+7` |
| `Hyper+T` | `Win+8` |
| `Hyper+0` | `Win+9` |
| `Hyper+O` | `Win+10` |

## Managing the service

```bash
systemctl status evremap
journalctl -u evremap -f
systemctl restart evremap
```
