# NixOS PXE Netboot Server

This directory contains a standalone Nix flake used to generate a minimal NixOS netboot environment.

It is designed to be paired with `pixiecore` to temporarily turn this machine into a PXE server. This allows you to boot blank computers over the local network directly into a live NixOS RAM disk, automatically injecting your SSH key for headless remote provisioning (via tools like `disko` and `nixos-anywhere`).

## Usage Instructions

### 1. Build the Netboot Image

Inside this directory, build the Flake to generate the kernel (`bzImage`) and RAM disk (`initrd`):

```bash
$ sudo start-pxe
```
