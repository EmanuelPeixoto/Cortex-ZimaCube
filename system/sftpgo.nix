{
  services.sftpgo = {
    enable = true;
    user = "sftpgo";
    group = "sftpgo";

    settings = {
      httpd = {
        bindings = [{ port = 8080; address = "0.0.0.0"; }];
      };
      sftpd = {
        bindings = [{ port = 2022; address = "0.0.0.0"; }];
      };
      data_provider = {
        name = "sqlite";
        default_user_permissions = [ "*" ];
      };
      common = {};
    };
  };

  systemd.services.sftpgo = {
    serviceConfig = {
      ReadWritePaths = [ "/mnt/nextcloud" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 2022 ];
}
