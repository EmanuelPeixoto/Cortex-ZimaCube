{ pkgs, ... }:

let
  # para instalar os pacotes por aqui, busque os disponiveis no nixpkgs ex.: rPackages.BiocManager e coloque apenas BiocManager abaixo.
  myRPackages = with pkgs.rPackages; [
    BiocManager
    DiagrammeR
    DiagrammeRsvg
    Matrix
    # UCSCXenaShiny
    # UCSCXenaTools
    # UCSC_utils
    UpSetR
    caret
    circlize
    data_table
    doParallel
    foreach
    fs
    ggplot2
    ggpubr
    ggtext
    gridExtra
    kableExtra
    lightgbm
    magick
    mice
    missForest
    openxlsx
    patchwork
    pheatmap
    pROC
    pdftools
    remotes
    rentrez
    reshape2
    rio
    R_utils
    rms
    rsvg
    Seurat
    SeuratObject
    sctransform
    stringi
    survival
    survivalROC
    survminer
    tidyverse
    tiff
    timeROC
    webshot2
    xgboost
  ];
in
  {
  services.rstudio-server = {
    enable = true;
    listenAddr = "0.0.0.0";
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
    "d /mnt/sharefiles/rlibs 2775 medina medina-group -"
  ];

  networking.firewall.allowedTCPPorts = [ 8787 ];
}
