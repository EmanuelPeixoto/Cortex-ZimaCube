{
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];

    xkb = {
      layout = "br";
      variant = "";
      model = "";
    };

    displayManager.lightdm.enable = true;
    desktopManager.cinnamon.enable = true;
  };
}
