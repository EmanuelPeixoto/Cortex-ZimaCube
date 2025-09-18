{
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      mail.enable = false;
      wall.enable = true;
    };
  };
}
