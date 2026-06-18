{ pkgs, ... }:
let
  myRPackages = import ./r-packages.nix { inherit pkgs; };

  rWithPackages = pkgs.rWrapper.override {
    packages = myRPackages;
  };
in
  {
  environment.systemPackages = [ rWithPackages ];

  users.groups.rlibs = {};

  services.rstudio-server = {
    enable = true;
    listenAddr = "0.0.0.0";

    rserverExtraConfig = ''
      www-port=8788
    '';

    rsessionExtraConfig = ''
      r-libs-user=/mnt/sharefiles/rlibs
    '';

    package = pkgs.rstudioServerWrapper.override {
      packages = myRPackages;
    };
  };

  systemd.services.rstudio-server = {
    path = with pkgs; [
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
  };

  systemd.tmpfiles.rules = [
    "d /mnt/sharefiles/rlibs 2775 root rlibs -"
  ];
}
