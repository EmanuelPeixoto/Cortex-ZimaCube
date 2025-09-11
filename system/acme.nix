{
  security.acme = {
    acceptTerms = true;
    defaults.email = "";
    defaults.webroot = "/var/lib/acme/acme-challenge";
    certs."MEU_DNS" = {
      email = "";
      group = "www";
    };
  };
}
