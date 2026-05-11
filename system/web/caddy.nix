{
  services.caddy = {
    enable = true;
    virtualHosts.":8787" = {
      extraConfig = ''
        redir /cancerrcdpredictor /cancerrcdpredictor/

        handle_path /cancerrcdpredictor/* {
          reverse_proxy localhost:8888 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Prefix /shiny
          }
        }

        handle /* {
          reverse_proxy localhost:8788
        }
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 8787 ];
}
