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

      www = {
        shell = pkgs.fish;
        isSystemUser = true;
        createHome = true;
        home = "/home/www";
        group = "www";
        extraGroups = [ "nextcloud" "wheel" ];
      };

      bio = {
        # Set fish to default shell
        shell = pkgs.fish;
        isNormalUser = true;
        createHome = true;
        extraGroups = [ "" ];
      };
    };

    groups.www = {
      name = "www";
      members = [ "nginx" "nextcloud" "acme" ];
    };
  };
}
