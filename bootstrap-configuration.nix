{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
  ];

  # Boot loader
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.enable = true;

  # Network
  networking.hostName = "amnezia-server";
  networking.useDHCP = true;

  # SSH on default port 22 for initial setup
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Tailscale for reliable remote access
  services.tailscale.enable = true;

  # Root password
  users.users.root.initialPassword = "test123";

  # Firewall - allow SSH
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Install git and essential tools
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    tailscale
  ];

  # Clone the configuration repo on first boot
  systemd.services.clone-amnezia-config = {
    description = "Clone AmneziaWG configuration";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '
          if [ ! -d /root/nix-amnezia ]; then
            cd /root && ${pkgs.git}/bin/git clone https://github.com/madnificent/nix-amnezia.git 2>/dev/null || true
          fi
        '
      '';
      RemainAfterExit = true;
    };
  };

  system.stateVersion = "24.11";
}
