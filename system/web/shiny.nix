{ pkgs, ... }:
let
  myRPackages = import ./r-packages.nix { inherit pkgs; };
  rWithPackages = pkgs.rWrapper.override {
    packages = myRPackages;
  };
in {
  users.users.shiny = {
    isNormalUser = true;
    group = "shiny";
    description = "Service account for CancerRCDShiny";
  };
  users.groups.shiny = {};

  systemd.services.shiny-zima-cancer = {
    description = "ZIMA Suit - CancerRCDShiny na porta 8888";
    after = [ "network.target" "rstudio-server.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "shiny";
      Group = "shiny";

      RuntimeDirectory = "shiny-zima-cancer";
      RuntimeDirectoryMode = "0777";

      ExecStartPre = "+${pkgs.coreutils}/bin/rm -rf /run/shiny-zima-cancer/*";

      ExecStart = "${rWithPackages}/bin/Rscript /mnt/sharefiles/PHASE_III_Megarun_5_0_complete_ZIMA_Suit_Generator_final/PHASE_IV_CancerRCDShiny/app.R";
      WorkingDirectory = "/mnt/sharefiles/PHASE_III_Megarun_5_0_complete_ZIMA_Suit_Generator_final/PHASE_IV_CancerRCDShiny";

      Restart = "always";
      RestartSec = "5s";

      Environment = [
        "HOME=/home/shiny"
        "R_BROWSER=false"
        "R_LIBS_USER=/mnt/sharefiles/rlibs"
        "R_PDFVIEWER=false"
        "R_SASS_CACHE_DIR=/run/shiny-zima-cancer/sass-cache"
        "SASS_PATH=/run/shiny-zima-cancer"
        "TMPDIR=/run/shiny-zima-cancer"
        "XDG_CACHE_HOME=/run/shiny-zima-cancer/cache"
      ];

      ReadWritePaths = [
        "/run/shiny-zima-cancer"
        "/mnt/sharefiles/rlibs"
        "/home/shiny"
      ];
    };
  };
}
