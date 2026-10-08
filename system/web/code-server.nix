{ pkgs, config, lib, ... }:
let
  # Mesmo r-packages.nix do RStudio (não alterado) + languageserver p/ autocomplete.
  myRPackages = import ./r-packages.nix { inherit pkgs; };

  rWithPackages = pkgs.rWrapper.override {
    packages = myRPackages ++ [ pkgs.rPackages.languageserver pkgs.rPackages.httpgd ];
  };

  # Python com torch/CUDA no PATH → reticulate/torch no R enxerga a GPU.
  # removeAttrs [ "doc" ] = mesmo contorno do apps.nix p/ não buildar o doc do python (bug sphinx/docutils).
  pythonTorch = removeAttrs (pkgs.python312.withPackages (ps: with ps; [
    torch
    torchvision
    torchaudio
    numpy
  ])) [ "doc" ];

  # Extensão R apontando pro nosso R (todos os pacotes), não o R base.
  rExt = pkgs.vscode-extensions.reditorsupport.r.override {
    R = rWithPackages;
  };

  codeServer = pkgs.vscode-with-extensions.override {
    vscode = pkgs.code-server;
    vscodeExtensions = with pkgs.vscode-extensions; [
      rExt
      reditorsupport.r-syntax
    ];
  };

  # PATH do code-server. Mesma toolchain do rstudio.nix (comprovada para
  # compilar pacotes R) + R + CUDA + git + python-torch.
  codePath = with pkgs; [
    rWithPackages
    pythonTorch
    cudatoolkit
    git
    astral
    bash
    binutils
    cairo
    chromium
    cmake
    coreutils
    curl.dev
    diffutils
    eigen
    fontconfig.dev
    freetype.dev
    gawk
    gcc
    getconf
    gfortran
    gnutar
    gnumake
    gzip
    imagemagick.dev
    libgit2
    libjpeg
    libpng.dev
    librsvg
    libtiff
    libxml2.dev
    musl
    nlopt
    openssl.dev
    pkg-config
    poppler
    toybox
    wget
    zlib.dev
  ];
in
{
  services.code-server = {
    enable = true;
    package = codeServer;
    host = "127.0.0.1";   # só atrás do Caddy (/v2)
    port = 8789;
    auth = "password";

    # senha atual: zimacube  (troque gerando novo hash abaixo e colando aqui)
    #   echo -n 'NOVA_SENHA' | nix run nixpkgs#libargon2 -- "$(head -c 20 /dev/random | base64)" -e
    hashedPassword = "$argon2i$v=19$m=4096,t=3,p=1$NGkrMWhGRTQ4dUtaaWZLcXBoUzBiSENGRWlZPQ$JcbddtmwCkFXaZL7BF0qajo6B/luM7mcrUBzWgYwO2A";

    user = "code-server";
    group = "code-server";
    extraGroups = [ "rlibs" ];

    extraPackages = codePath;

    extraEnvironment = {
      R_LIBS_USER = "/mnt/sharefiles/rlibs";
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    };

    # atrás do Caddy em /v2
    extraArguments = [ "--abs-proxy-base-path=/v2" ];

    disableTelemetry = true;
    disableUpdateCheck = true;
    disableGettingStartedOverride = true;
  };

  users.groups.rlibs = {};

  systemd.tmpfiles.rules = [
    "d /mnt/sharefiles/rlibs 2775 root rlibs -"
  ];
}
