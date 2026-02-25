#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== NixOS Install Script ==="

# Mount if not already mounted
mountpoint -q /mnt || { echo "Mounting /dev/sda1..."; sudo mount /dev/sda1 /mnt; }
mountpoint -q /mnt/boot || { echo "Mounting /dev/sda15..."; sudo mkdir -p /mnt/boot; sudo mount /dev/sda15 /mnt/boot; }

# Generate hardware config if missing
if [ ! -f /mnt/etc/nixos/hardware-configuration.nix ]; then
  echo "Generating hardware config..."
  sudo nixos-generate-config --root /mnt
fi

# Copy config
sudo cp "$SCRIPT_DIR/bootstrap-configuration.nix" /mnt/etc/nixos/configuration.nix
echo "Config copied."

# Copy tailscale state if it exists
if [ -f /var/lib/tailscale/tailscaled.state ]; then
  sudo mkdir -p /mnt/var/lib/tailscale
  sudo cp -a /var/lib/tailscale/* /mnt/var/lib/tailscale/
  echo "Tailscale state copied."
fi

echo "Running nixos-install..."
sudo nixos-install --root /mnt --no-root-passwd

echo "=== Done! Run: sudo reboot ==="
