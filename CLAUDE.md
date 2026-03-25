# Nix-on-Droid (joni-android fork)

## Project Overview

Nix-on-Droid brings the Nix package manager to Android without root, user namespaces, or SELinux changes. It uses **PRoot** (userspace chroot) for filesystem translation and ships as a **Termux-based terminal emulator app** (separate repo: `nix-community/nix-on-droid-app`).

This repo contains the **Nix-side infrastructure**: module system, bootstrap builder, cross-compilation, deployment scripts, and tests. It does NOT contain the Android app source code (Java/Kotlin/Gradle).

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Android Device                                  │
│  ┌───────────────────────────────────────────┐  │
│  │  Termux App (com.termux.nix)              │  │
│  │  └─ login script                          │  │
│  │     └─ proot-static (bind mounts)         │  │
│  │        └─ /nix/store (Nix environment)    │  │
│  │           └─ login-inner (shell init)     │  │
│  │              └─ user's shell (bash/zsh)   │  │
│  └───────────────────────────────────────────┘  │
│  Install dir: /data/data/com.termux.nix/files/usr│
└─────────────────────────────────────────────────┘
```

**Key flow**: App launches → `login` script → invokes `proot-static` with bind mounts → enters Nix environment → `login-inner` initializes Nix → user shell.

## Required Technologies

- **Nix** (flake-enabled, 2.20+ recommended) — build system and package manager
- **x86_64-linux** host — for building (cross-compiles to aarch64/x86_64 Android)
- **Android NDK** (via nixpkgs cross-compilation) — for proot-static
- **Cachix** (optional) — binary cache at `nix-on-droid.cachix.org`
- **BATS** — on-device test framework
- **Python 3** + UIAutomator — emulator tests
- **Android SDK/emulator** (API 29) — for CI emulator tests
- **droidctl** (`github:t184256/droidctl`) — Android device automation for tests

## Build Commands

```bash
# Build the nix-on-droid CLI tool
nix build .#nix-on-droid

# Build bootstrap zipball for ARM64 phones (requires --impure for proot store paths)
nix build .#bootstrapZip-aarch64 --impure

# Build bootstrap zipball for x86_64 (emulator testing)
nix build .#bootstrapZip-x86_64 --impure

# Build proot-termux standalone
nix build .#prootTermux-aarch64 --impure
nix build .#prootTermux-x86_64 --impure

# Build HTML documentation
nix build .#manualHtml

# Build man pages
nix build .#manPages

# Run linter/formatter check
nix build .#checks.x86_64-linux.nix-formatter-pack-check

# Format code
nix fmt

# Deploy (build + upload bootstrap + channel tarball)
nix run .#deploy -- <public_url> <rsync_target>
```

## Testing

```bash
# On-device tests (run inside nix-on-droid on a device/emulator):
nix-on-droid on-device-test
# WARNING: destructive, only on disposable installations

# CI emulator tests (GitHub Actions, see .github/workflows/emulator.yml):
# These use droidctl + Android emulator + Python UIAutomator
# Not easily run locally without full Android SDK setup
```

## Key Directories

| Path | Purpose |
|------|---------|
| `flake.nix` | Main entry: inputs, outputs, packages, templates, lib |
| `modules/` | NixOS-style module system for Android environment config |
| `modules/build/` | Activation scripts, build config, initial bootstrap |
| `modules/environment/` | Shell, path, nix, networking, login, Android integration |
| `modules/environment/login/` | PRoot invocation (`login.nix`) and shell init (`login-inner.nix`) |
| `pkgs/` | Package definitions: bootstrap, proot, cross-compilation |
| `pkgs/cross-compiling/` | Android cross-compilation: proot-termux, talloc, patches |
| `pkgs/bootstrap.nix` | Assembles bootstrap directory structure |
| `pkgs/bootstrap-zip.nix` | Zips bootstrap into distributable zipball |
| `pkgs/nix-directory.nix` | Downloads and initializes Nix 2.20.5 binary |
| `nix-on-droid/` | CLI tool (`nix-on-droid.sh`) + its Nix packaging |
| `overlays/` | Nixpkgs overlays (typespeed fix, bootstrap nixpkgs pin) |
| `templates/` | User config templates (minimal, home-manager, advanced) |
| `tests/on-device/` | BATS tests (*.bats) + test configs (*.nix) |
| `tests/emulator/` | Python emulator tests (UIAutomator-based) |
| `scripts/` | Deployment script |
| `docs/` | Documentation build (nmd → HTML + man pages) |
| `.github/workflows/` | CI: lints, cachix, emulator tests, docs deployment |

## Pinned Versions (flake.lock — as of fork, STALE)

| Input | Pinned Date | Notes |
|-------|-------------|-------|
| nixpkgs | 2024-02-17 | **Very old** — needs updating |
| nixpkgs-for-bootstrap | 2024-07-06 | nixos-24.05, used for proot + bootstrap |
| home-manager | 2024-03-03 | Follows nixpkgs |
| nix-formatter-pack | 2024-01-14 | Linting tools |
| nmd | 2024-01-12 | Documentation generator |
| nixpkgs-docs | release-23.05 | For doc generation only |

## Update Plan (Nix Compatibility)

To update for latest Nix versions:

1. **Update flake inputs**: `nix flake update` (bumps nixpkgs, home-manager, etc.)
2. **Update nixpkgs-for-bootstrap**: Pick a recent nixos-24.11 or nixos-25.05 commit
3. **Rebuild proot-termux**: After nixpkgs-for-bootstrap update, cross-compile proot and update hardcoded store paths in `modules/environment/login/default.nix`
4. **Update Nix version**: `pkgs/nix-directory.nix` pins Nix 2.20.5 — update to latest
5. **Fix breakage**: Module system, overlays, and package definitions may need fixes for nixpkgs API changes
6. **Test**: Build bootstrap zip, test on emulator or device
7. **Deploy**: Run deploy script to publish new bootstrap

## Hardcoded Store Paths (IMPORTANT)

`modules/environment/login/default.nix` contains hardcoded `/nix/store/...` paths for proot-termux binaries. These must be updated whenever proot-termux is rebuilt with a different nixpkgs-for-bootstrap. The deploy script (`scripts/deploy.sh`) handles this automatically.

## Cross-Compilation Details

Target: `{arch}-unknown-linux-android` with:
- SDK version: 32
- libc: bionic
- LLVM toolchain (not GCC)
- Static linking

PRoot source: Termux fork at `github:nickcao/proot` (rev: 60485d2646c1e09105099772da4a20deda8d020d)

## Configuration (End-User)

Users configure their device via:
- **Channel-based**: `~/.config/nixpkgs/nix-on-droid.nix`
- **Flake-based**: `~/.config/nix-on-droid/flake.nix` (requires `--impure`)

Apply with: `nix-on-droid switch`
