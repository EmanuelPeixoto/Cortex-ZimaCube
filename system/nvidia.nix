{ config, pkgs, ...}:
{

  environment.systemPackages = [
    pkgs.glxinfo
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;

  boot = {
    extraModprobeConfig = "options nvidia-drm modeset=1";
    blacklistedKernelModules = [ "nouveau" ];
  };

  systemd.services.systemd-udev-trigger.restartIfChanged = false;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidiaOptimus.disable = false;

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      modesetting.enable = true;

      powerManagement = {
        enable = false;
        finegrained = false;
      };

      open = false;

      nvidiaSettings = true;

      prime = {
        offload = {
          enable = false;
          enableOffloadCmd = false;
        };
        sync.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:7:0:0";
      };
    };
  };
}
