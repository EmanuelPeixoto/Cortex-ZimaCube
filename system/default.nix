{
  imports = [
    ./alunos.nix
    ./apps.nix
    ./docker.nix
    ./firewall.nix
    ./flake-config.nix
    ./hardware-configuration.nix
    ./locale.nix
    ./nextcloud
    ./ngrok.nix
    ./nvidia.nix
    ./rstudio.nix
    ./smartd.nix
    ./sound.nix
    ./ssh.nix
    ./users.nix
    ./web
    ./xserver.nix
    ./zfs.nix
  ];

  # Hostname
  networking.hostName = "NixOS-ZimaCube";

  # Boot
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Networking
  networking.networkmanager.enable = true;

  programs = {
    dconf.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };

  services = {
    vnstat.enable = true;
  };

  system.stateVersion = "25.05";
}
