{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.ngrok
  ];

  systemd.services.ngrok-ssh = {
    description = "ngrok TCP SSH tunnel system-wide";
    after = [ "network.target" ];
    wants = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ngrok}/bin/ngrok tcp 22";
      Restart = "always";
      RestartSec = 10;
      User = "zimacube";
    };

    wantedBy = [ "multi-user.target" ];
  };
}
