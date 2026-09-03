{ pkgs, lib, ... }:
let
  myRPackages = import ./r-packages.nix { inherit pkgs; };
  rWithPackages = pkgs.rWrapper.override {
    packages = myRPackages;
  };

  # Factory: gera um atributo systemd.services a partir de um conjunto de opções
  mkShinyService = {
    name,          # string curta, ex: "cancer"
    port,          # int, ex: 8888
    appPath,       # path absoluto para o app.R
    extraEnv ? {}, # atributos extras de Environment (opcional)
    }:
    let
      svcName  = "shiny-zima-${name}";
      runDir   = "/run/${svcName}";
      appDir   = builtins.dirOf appPath;
      userName = "shiny-${name}";
    in {
      # User/group por serviço
      users.users.${userName} = {
        isNormalUser = true;
        group        = userName;
        extraGroups  = [ "rlibs" ];
        description  = "Service account for shiny-${name}";
      };
      users.groups.${userName} = {};

      systemd.services.${svcName} = {
        description = "ZIMA Suit — Shiny ${name} na porta ${toString port}";
        after       = [ "network.target" ];
        wantedBy    = [ "multi-user.target" ];

        path = [ pkgs.chromium ];

        serviceConfig = {
          User  = userName;
          Group = userName;

          RuntimeDirectory     = svcName;
          RuntimeDirectoryMode = "0755";

          ExecStartPre = "+${pkgs.coreutils}/bin/rm -rf ${runDir}/*";
          ExecStart    = "${rWithPackages}/bin/Rscript ${appPath}";
          WorkingDirectory = appDir;

          Restart    = "always";
          RestartSec = "5s";

          Environment = lib.mapAttrsToList (k: v: "${k}=${v}") ({
            HOME            = "/run/${svcName}";
            R_BROWSER       = "false";
            R_LIBS_USER     = "/mnt/sharefiles/rlibs";
            R_PDFVIEWER     = "false";
            R_SASS_CACHE_DIR = "${runDir}/sass-cache";
            SASS_PATH       = runDir;
            TMPDIR          = runDir;
            XDG_CACHE_HOME  = "${runDir}/cache";
          } // extraEnv);

          ReadWritePaths = [
            runDir
            "/mnt/sharefiles/rlibs"
            "/run/${svcName}"
          ];
        };
      };
    };

  services = map mkShinyService [
    {
      name    = "crcdp";
      port    = 8888;
      appPath = "/mnt/sharefiles/servicos/PHASE_III_Megarun_5_0_complete_ZIMA_Suit_Generator_final/PHASE_IV_CancerRCDShiny/appV2.R";
    }
    {
      name    = "rcdsurvxai";
      port    = 8889;
      appPath = "/mnt/sharefiles/servicos/RCDSurvXai/02_OncoSurvXai_Shiny_V25.R";
    }
        {
      name    = "rcdome";
      port    = 8890;
      appPath = "/mnt/sharefiles/servicos/RCDome_Atlas/APP/run.R";
    }
  ];

in
  lib.foldl' lib.recursiveUpdate {} services
