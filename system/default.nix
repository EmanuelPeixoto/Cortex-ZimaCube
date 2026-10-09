{
  imports = [
    ./alunos.nix
    ./apps.nix
    ./docker.nix
    ./firewall.nix
    ./flake-config.nix
    ./hardware-configuration.nix
    ./ia.nix
    ./locale.nix
    ./ngrok.nix
    ./nvidia.nix
    ./smartd.nix
    ./sound.nix
    ./ssh.nix
    ./users.nix
    ./video-ai.nix
    ./web
    ./xserver.nix
    ./zfs.nix
  ];

  # Hostname
  networking.hostName = "NixOS-ZimaCube";

  # Boot
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = false;
  };

  # Networking
  networking.networkmanager.enable = true;

  programs = {
    dconf.enable = true;
    fish.enable = true;
    zsh.enable = true;
    nix-ld.enable = true;
  };

  services = {
    vnstat.enable = true;
  };

  # CPU: governor performance (prefere o boost máximo). Remova esta linha p/ voltar ao powersave.
  powerManagement.cpuFreqGovernor = "performance";

  # Bump dos power limits do i5-1235U (valores em microwatts, uW).
  # Padrões de fábrica: PL1 = 28000000 (28W) | PL2 = 42000000 (42W).
  # Para mudar: edite os números. Para reverter: volte aos padrões OU comente/remova este serviço inteiro.
  # Obs.: se o MSR estiver travado (mitigação Plundervolt), o echo falha silenciosamente (|| true).
  systemd.services.cpu-power-bump = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      RemainAfterExit = true;
    };
    script = ''
      # PL1 (sustentado): 28W -> 40W
      echo 40000000 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw || true
      # PL2 (burst): 42W -> 50W
      echo 50000000 > /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw || true
    '';
  };

  system.stateVersion = "25.05";
}
