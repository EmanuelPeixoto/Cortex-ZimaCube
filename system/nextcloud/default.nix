{ config, pkgs, ... }:
{
  imports = [
    ./database.nix
    #./facerecognition.nix
    ./php.nix
  ];

  services.nextcloud = {
    enable = true;
    #https = true;
    hostName = "${config.networking.hostName}.local";
    package = pkgs.nextcloud31;
    maxUploadSize = "16384M";

    settings = {
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "05:00:00";
      filesystem_check_changes = 1;
      logLevel = 1;
      log_type = "file";
      trusted_domains = [
        "${config.networking.hostName}.local"
      ];
      memcache.local = "\\OC\\Memcache\\APCu";
      filelocking.enabled = true;
    };

    config.adminpassFile = "${pkgs.writeText "adminpass" "test123"}";
  };
}
