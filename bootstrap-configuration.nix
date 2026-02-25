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

  # SSH on custom port 10022
  services.openssh = {
    enable = true;
    ports = [ 10022 ];
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Root password
  users.users.root.initialPassword = "test123";

  # Firewall - allow SSH on port 10022
  networking.firewall.allowedTCPPorts = [ 10022 ];

  # Install git and essential tools
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
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
