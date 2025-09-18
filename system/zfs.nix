{
  boot = {
    kernelModules = [ "zfs" ];
    zfs.extraPools = [ "nextcloud" ];
    supportedFilesystems.zfs = true;
  };

  networking.hostId = "0de1206c"; # head -c 8 /etc/machine-id

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    autoSnapshot = {
      enable = true;
      daily = 7;
      weekly = 4;
      };
  };
}

