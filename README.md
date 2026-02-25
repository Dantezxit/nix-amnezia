# nix-amnezia

NixOS configuration for AmneziaWG VPN server with automatic updates and easy deployment.

## Quick Start

### Clone the Configuration

```bash
git clone https://github.com/madnificent/nix-amnezia.git
cd nix-amnezia
```

### Using the Bootstrap Configuration

The `bootstrap-configuration.nix` is a minimal configuration for initial VPS setup with a non-standard SSH port (10022):

```bash
# On a fresh NixOS VPS, use this to set up the base system
sudo cp bootstrap-configuration.nix /etc/nixos/configuration.nix
sudo cp hardware-configuration.nix /etc/nixos/hardware-configuration.nix  # Generate this on your VPS first

# Or use it directly with flakes:
sudo nixos-rebuild switch --flake .#
```

**Features:**
- SSH on custom port `10022` (allows avoiding automated attacks on port 22)
- Password authentication enabled for initial setup
- Essential tools pre-installed: git, vim, wget, curl
- Automatic git clone of config repo on first boot
- DHCP networking by default

**Note:** Change the root password immediately after first login!

### Full AmneziaWG Configuration

Once the server is set up, use `configuration.nix` for the full AmneziaWG VPN setup:

```bash
sudo nixos-rebuild switch --flake .
```

## Server Details

- **VPS IP**: 188.245.237.184
- **VPN Interface**: awg0
- **VPN Port**: 51820 (UDP)
- **VPN Subnet**: 10.200.200.0/24
- **Server VPN IP**: 10.200.200.1/24
- **SSH Port**: 10022 (bootstrap) / 22 (production)

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

### 1. Initial Server Setup (Bootstrap Phase)

On your fresh NixOS VPS:

```bash
# SSH to your VPS on the default port 22
ssh root@188.245.237.184

# Create the directory for AmneziaWG keys
sudo mkdir -p /var/lib/amneziawg

# Generate server keys
sudo awg genkey | sudo tee /var/lib/amneziawg/private-key
sudo chmod 600 /var/lib/amneziawg/private-key

# Get the server public key
sudo cat /var/lib/amneziawg/private-key | awg pubkey
```

### 2. Switch to Custom SSH Port (Bootstrap)

After cloning the config:

```bash
# Apply bootstrap configuration
sudo nixos-rebuild switch --flake .

# Reconnect on port 10022
ssh -p 10022 root@188.245.237.184
```

### 3. Add Client Keys

Generate keys on your iOS device using AmneziaWG app, or generate them locally:

```bash
awg genkey | tee privatekey | awg pubkey > publickey
cat publickey  # Copy this for the configuration
```

Edit `configuration.nix` and update the client public key:

```nix
clients = [
  {
    name = "iphone";
    publicKey = "YOUR_ACTUAL_CLIENT_PUBLIC_KEY";  # Replace this
    allowedIPs = [ "10.200.200.2/32" ];
    persistentKeepalive = 25;
  }
];
```

### 4. Deploy Full Configuration

```bash
sudo nixos-rebuild switch --flake .
```

### 5. iOS Client Configuration

In the AmneziaWG iOS app, create a new tunnel with:

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
- Public Key: [Your server public key]
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
sudo journalctl -u wg-quick-awg0 -f
```

Test connectivity from server:
```bash
ping 10.200.200.2  # Client IP
```

Check SSH status:
```bash
sudo systemctl status ssh
sudo journalctl -u ssh -f
```

## Security Notes

- Bootstrap config allows password auth for initial setup
- Production config uses key-based authentication only
- Root login requires key-based authentication in production
- Private keys stored in `/var/lib/amneziawg/` with 0700 permissions
- Firewall allows only UDP port 51820 for VPN (and SSH on 10022 during bootstrap)

## Troubleshooting

### Connection fails after deployment

1. Verify AmneziaWG parameters match exactly:
   ```bash
   sudo awg show
   ```

2. Check firewall rules:
   ```bash
   sudo iptables -L -n -v
   ```

3. Verify NAT rules:
   ```bash
   sudo iptables -t nat -L -n -v
   ```

4. Check logs:
   ```bash
   sudo journalctl -u wg-quick-awg0 -f
   ```

5. Ensure IP forwarding is enabled:
   ```bash
   sysctl net.ipv4.ip_forward
   ```

### SSH Connection Issues

If you can't connect after switching to port 10022:

```bash
# Check SSH is listening
sudo ss -tlnp | grep ssh

# View SSH logs
sudo journalctl -u ssh -n 50

# Verify firewall allows the port
sudo iptables -L -n | grep 10022
```

## Files

- `bootstrap-configuration.nix` - Minimal config for VPS initialization with SSH on port 10022
- `configuration.nix` - Full AmneziaWG server configuration with auto-updates
- `flake.nix` - Flake configuration for easy deployment
- `hardware-configuration.nix` - Hardware settings (generate with `nixos-generate-config`)
- `CLAUDE.md` - Development notes

## License

This configuration is provided as-is for personal use.
