{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  # Boot
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Network
  networking.hostName = "amnezia-server";
  networking.useDHCP = lib.mkDefault true;

  # Firewall - allow SSH only for now
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Packages - minimal set
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
  ];

  # SSH - standard port for initial setup
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYy3d4b/Zb/cNZfxe2ERtbK/RYBntOlJCfxqSJIS+Hm dante@nixos-404-dubsof"
  ];

  # Time sync
  services.timesyncd.enable = true;
}
