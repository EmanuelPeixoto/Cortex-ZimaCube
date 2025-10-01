{
  services.rstudio-server = {
    enable = true;
    listenAddr = "0.0.0.0";
  };

  networking.firewall.allowedTCPPorts = [ 8787 ];
}
