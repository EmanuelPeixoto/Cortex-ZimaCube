{ config, pkgs, ... }:
{
  imports = [
    ./database.nix
    ./php.nix
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/nextcloud/data 0770 nextcloud nextcloud -"
  ];

  services.nextcloud = {
    enable = true;
    hostName = "${config.networking.hostName}.local";
    package = pkgs.nextcloud31;
    maxUploadSize = "16384M";
    datadir = "/mnt/nextcloud";

    settings = {
      filesystem_check_changes = 1;
      logLevel = 1;
      log_type = "file";
      trusted_domains = [
        "${config.networking.hostName}.local"
        "172.20.53.238"
      ];
      memcache.local = "\\OC\\Memcache\\APCu";
      filelocking.enabled = true;
    };

    config.adminpassFile = "${pkgs.writeText "adminpass" "test123"}";
  };
}
