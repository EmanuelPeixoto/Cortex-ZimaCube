{ pkgs, ... }:
{
  users = {
    users = {
      zimacube = {
        shell = pkgs.zsh;
        isNormalUser = true;
        description = "ZimaCube";
        extraGroups = [ "networkmanager" "wheel" ];
      };
    };
  };
}
