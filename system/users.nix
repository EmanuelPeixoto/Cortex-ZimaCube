{ pkgs, ... }:
{
  users = {
    users = {
      shiny-rcdsurvxai.extraGroups = [ "wheel" ];
      zimacube = {
        shell = pkgs.zsh;
        isNormalUser = true;
        description = "ZimaCube";
        extraGroups = [ "networkmanager" "wheel" ];
      };
    };
  };
}
