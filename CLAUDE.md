# AmneziaWG NixOS Server

This repository contains a NixOS configuration for an AmneziaWG VPN server with automatic updates, designed to work with the Amnezia iOS app.

## Server Details

- **VPS IP**: 188.245.237.184
- **VPN Interface**: awg0
- **VPN Port**: 51820 (UDP)
- **VPN Subnet**: 10.200.200.0/24
- **Server VPN IP**: 10.200.200.1/24

## AmneziaWG Parameters

These parameters must match on both server and iOS client:

```
Jc = 8         # Junk packet count
Jmin = 120     # Min junk packet size
Jmax = 320     # Max junk packet size
S1 = 60        # Init packet padding
S2 = 90        # Response packet padding
S3 = 30        # Cookie packet padding
S4 = 15        # Data packet padding
H1 = 2008066467
H2 = 2351746464
H3 = 3053333659
H4 = 1789444460
```

## Setup Instructions

### 1. Initial Server Setup

On your VPS, generate the server keys:

```bash
sudo mkdir -p /var/lib/amneziawg
sudo awg genkey | sudo tee /var/lib/amneziawg/private-key
sudo chmod 600 /var/lib/amneziawg/private-key
```

Get the server public key:
```bash
sudo cat /var/lib/amneziawg/private-key | awg pubkey
```

### 2. Add Client Keys

Edit `configuration.nix` and replace `YOUR_CLIENT_PUBLIC_KEY_HERE` with your iOS device's public key.

Generate client keys on your iPhone using the AmneziaWG app, or use:
```bash
awg genkey | tee privatekey | awg pubkey > publickey
```

### 3. Deploy Configuration

```bash
sudo nixos-rebuild switch --flake .
```

### 4. iOS Client Configuration

In the AmneziaWG iOS app, create a new tunnel with these settings:

**Interface:**
- Private Key: [Your iOS private key]
- Addresses: 10.200.200.2/32
- DNS: 1.1.1.1, 8.8.8.8
- Jc: 8
- Jmin: 120
- Jmax: 320
- S1: 60
- S2: 90
- S3: 30
- S4: 15
- H1: 2008066467
- H2: 2351746464
- H3: 3053333659
- H4: 1789444460

**Peer:**
- Public Key: [Server public key from step 1]
- Allowed IPs: 0.0.0.0/0
- Endpoint: 188.245.237.184:51820
- Persistent Keepalive: 25

## Auto-Updates

The server automatically updates daily at 4:00 AM with:
- System updates via `nixos-rebuild switch --upgrade`
- Automatic reboot if needed (only between 3:00-5:00 AM)
- Weekly garbage collection (keeps 30 days of generations)
- Store optimization

## Management Commands

Check AmneziaWG status:
```bash
sudo awg show
```

View logs:
```bash
sudo journalctl -u wg-quick-awg0
```

Test connectivity:
```bash
ping 10.200.200.2  # From server to client
```

## Security Notes

- SSH password authentication is disabled
- Root login requires key-based authentication
- Private keys are stored in `/var/lib/amneziawg/` with 0700 permissions
- Firewall allows only UDP port 51820

## Troubleshooting

If connection fails:
1. Verify AmneziaWG parameters match exactly on both ends
2. Check firewall rules: `sudo iptables -L -n -v`
3. Verify NAT rules: `sudo iptables -t nat -L -n -v`
4. Check logs: `sudo journalctl -u wg-quick-awg0 -f`
5. Ensure IP forwarding is enabled: `sysctl net.ipv4.ip_forward`

## Files

- `flake.nix` - Flake configuration
- `configuration.nix` - Main NixOS configuration
- `hardware-configuration.nix` - Hardware settings (generate with `nixos-generate-config`)
