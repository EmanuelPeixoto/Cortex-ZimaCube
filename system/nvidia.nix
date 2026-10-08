{ config, pkgs, ...}:
{

  environment.systemPackages = [
    pkgs.mesa-demos
  ];

  boot = {
    extraModprobeConfig = "options nvidia-drm modeset=1";
    initrd.kernelModules = [ "nvidia_modeset" ];
    blacklistedKernelModules = [ "nouveau" ];
  };

  systemd.services.systemd-udev-trigger.restartIfChanged = false;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      modesetting.enable = true;

      # Monitor na iGPU Intel; nvidia só pra compute (CUDA).
      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:7:0:0";
      };

      powerManagement = {
        enable = false;
        finegrained = false;
      };

      open = false;

      nvidiaSettings = true;
    };
  };
}
