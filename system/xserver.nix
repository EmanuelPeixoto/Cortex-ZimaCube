{
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    xkb = {
      layout = "br";
      variant = "";
      model = "";
    };

    displayManager.lightdm.enable = true;
    desktopManager.cinnamon.enable = true;
  };
}
