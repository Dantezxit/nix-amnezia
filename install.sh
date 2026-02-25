#!/bin/bash
set -e

echo "=== NixOS Install Script ==="

# Copy config
cp /root/nix-amnezia/bootstrap-configuration.nix /mnt/etc/nixos/configuration.nix
echo "Config copied."

# Copy tailscale state if it exists
if [ -d /var/lib/tailscale ] && [ -f /var/lib/tailscale/tailscaled.state ]; then
  mkdir -p /mnt/var/lib/tailscale
  cp -a /var/lib/tailscale/* /mnt/var/lib/tailscale/
  echo "Tailscale state copied."
fi

echo "Running nixos-install..."
nixos-install --root /mnt --no-root-passwd

echo "=== Done! Run: reboot ==="
