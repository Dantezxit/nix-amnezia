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

  # Root user with password "test123"
  users.users.root.hashedPassword = "$6$JLw2//9Qs.h.pQgo$debvCXuaHEQrwz3s2nNITyF3pU4hqd3IIEls9aUqJMZ5Um.5rjMDqv7SqBEu76bEeZHLXlaG3IeD0RsSWmtlx0";

  # Keep nixos user (Hetzner default) with sudo access
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$JLw2//9Qs.h.pQgo$debvCXuaHEQrwz3s2nNITyF3pU4hqd3IIEls9aUqJMZ5Um.5rjMDqv7SqBEu76bEeZHLXlaG3IeD0RsSWmtlx0";
  };

  # Allow wheel group to sudo
  security.sudo.wheelNeedsPassword = false;

  # Firewall - allow SSH
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Install git and essential tools
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    tailscale
  ];

  system.stateVersion = "24.11";
}
