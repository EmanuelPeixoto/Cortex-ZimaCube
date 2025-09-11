{ config, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.sessionVariables.NH_FLAKE = "${config.users.users.zimacube.home}/.config/Cortex-ZimaCube";
}
