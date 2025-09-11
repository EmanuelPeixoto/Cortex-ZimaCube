{ config, ... }:
{
  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    serverName = config.services.nextcloud.hostName;
    listen = [{
      addr = "0.0.0.0";
      port = 80;
      #ssl = true;
    }];

    #enableACME = true;
    #forceSSL = true;

    extraConfig = ''
      access_log /var/log/nginx/nextcloud-access.log;
      error_log /var/log/nginx/nextcloud-error.log;
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
