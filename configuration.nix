{ config, pkgs, lib, ... }:

let
  # AmneziaWG Configuration
  awgPort = 51820;
  awgInterface = "awg0";
  
  # VPN Network Configuration
  vpnSubnet = "10.200.200.0/24";
  serverIp = "10.200.200.1/24";
  
  # AmneziaWG Obfuscation Parameters (must match on client)
  # These values provide DPI resistance
  awgParams = {
    # Junk packets configuration
    Jc = 8;       # Number of junk packets (1-128, recommended 4-12)
    Jmin = 120;   # Min size of junk packets (must be < Jmax and < 1280)
    Jmax = 320;   # Max size of junk packets (must be > Jmin and < 1280)
    
    # Random padding for packet types
    S1 = 60;      # Padding for Init packets (0-64)
    S2 = 90;      # Padding for Response packets (0-64)
    S3 = 30;      # Padding for Cookie packets (0-64)
    S4 = 15;      # Padding for Data packets (0-32)
    
    # Dynamic headers (must be unique and non-overlapping)
    H1 = 2008066467;  # Header for Init packets
    H2 = 2351746464;  # Header for Response packets
    H3 = 3053333659;  # Header for Cookie packets
    H4 = 1789444460;  # Header for Data packets
  };

  # Example client configuration - REPLACE WITH YOUR CLIENT PUBLIC KEYS
  clients = [
    {
      name = "iphone";
      publicKey = "YOUR_CLIENT_PUBLIC_KEY_HERE";  # Replace with actual client public key
      allowedIPs = [ "10.200.200.2/32" ];
      persistentKeepalive = 25;
    }
    # Add more clients as needed
  ];
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # System configuration
  system.stateVersion = "24.11";

  # Boot configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelModules = [ "amneziawg" ];

  # Hostname
  networking.hostName = "amnezia-server";

  # Network configuration
  networking.useDHCP = lib.mkDefault true;
  
  # Enable IP forwarding for VPN
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ awgPort ];
    
    # NAT configuration for VPN clients
    extraCommands = ''
      # Enable NAT for VPN subnet
      iptables -t nat -A POSTROUTING -s ${vpnSubnet} -o eth0 -j MASQUERADE
      
      # Allow forwarding from VPN to internet
      iptables -A FORWARD -i ${awgInterface} -o eth0 -j ACCEPT
      iptables -A FORWARD -i eth0 -o ${awgInterface} -m state --state RELATED,ESTABLISHED -j ACCEPT
    '';
    
    extraStopCommands = ''
      iptables -t nat -D POSTROUTING -s ${vpnSubnet} -o eth0 -j MASQUERADE 2>/dev/null || true
      iptables -D FORWARD -i ${awgInterface} -o eth0 -j ACCEPT 2>/dev/null || true
      iptables -D FORWARD -i eth0 -o ${awgInterface} -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    '';
  };

  # AmneziaWG Configuration using wg-quick
  networking.wg-quick.interfaces.${awgInterface} = {
    # Enable AmneziaWG mode
    type = "amneziawg";
    
    # Interface configuration
    address = [ serverIp ];
    listenPort = awgPort;
    privateKeyFile = "/var/lib/amneziawg/private-key";
    
    # AmneziaWG-specific obfuscation parameters
    extraOptions = awgParams;
    
    # Client peers
    peers = map (client: {
      inherit (client) publicKey allowedIPs;
      inherit (client) persistentKeepalive;
    }) clients;
  };

  # Auto-updates configuration
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";  # Run at 4:00 AM daily
    randomizedDelaySec = "45min";  # Add random delay up to 45 minutes
    allowReboot = true;  # Reboot if kernel or critical system updates
    
    # Reboot window (optional) - only reboot during these hours
    rebootWindow = {
      lower = "03:00";
      upper = "05:00";
    };
  };

  # Garbage collection to prevent disk filling up
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Store optimization
  nix.optimise.automatic = true;

  # Required packages
  environment.systemPackages = with pkgs; [
    amneziawg-tools
    wireguard-tools
    qrencode      # For generating QR codes for client configs
    iptables
  ];

  # Ensure private key directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/amneziawg 0700 root root -"
  ];

  # SSH configuration for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Time synchronization
  services.timesyncd.enable = true;

  # Logging
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxFileSec=7day
  '';
}
