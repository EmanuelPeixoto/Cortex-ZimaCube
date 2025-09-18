{
  services.rstudio-server = {
    enable = true;
    listenAddr = "0.0.0.0";
    rserverExtraConfig = "www-root-path=/rstudio";
  };
}
