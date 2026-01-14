{
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "0de1206c"; # head -c 8 /etc/machine-id

  fileSystems."/mnt/sharefiles" = {
    device = "storage/sharefiles";
    fsType = "zfs";
  };

  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      flags = "-k -p --utc";
    };
  };
}
