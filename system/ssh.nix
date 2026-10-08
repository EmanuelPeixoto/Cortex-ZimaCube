{
  services.openssh = {
    enable = true;
    allowSFTP = false;
    settings = {
      PermitRootLogin = "no";
      # PasswordAuthentication = false;
    };
  };
}
