{ pkgs }:
let
  # gganatogram só existe no GitHub (não está no CRAN/nixpkgs).
  gganatogram = pkgs.rPackages.buildRPackage {
    name = "gganatogram-1.1.1";
    src = pkgs.fetchFromGitHub {
      owner = "jespermaag";
      repo  = "gganatogram";
      rev   = "eac6df5d3a6ac1a4404f2516e1e71a60274a6a0f";
      hash  = "sha256-cOnQB20cwPeEeNaYS5XNu2dmrP9UIb47bfTKI37wkG8=";
    };
    propagatedBuildInputs = with pkgs.rPackages; [ ggpolypath ggplot2 ];
  };
in
with pkgs.rPackages; [
  AnnotationDbi
  BiocManager
  DT
  DiagrammeR
  pkgs.unstable.rPackages.DiagrammeRsvg
  GSVA
  Matrix
  R_utils
  Seurat
  SeuratObject
  UCSCXenaShiny
  UpSetR
  base64enc
  blastula
  bsicons
  bslib
  caret
  circlize
  curl
  data_table
  digest
  doParallel
  dplyr
  emayili
  filelock
  foreach
  fs
  ggplot2
  ggpolypath
  gganatogram
  ggpubr
  ggtext
  gridExtra
  htmlwidgets
  httr
  httr2
  jsonlite
  kableExtra
  lightgbm
  magick
  mice
  missForest
  openxlsx
  pROC
  pagedown
  pak
  patchwork
  pdftools
  pheatmap
  plotly
  readr
  readxl
  remotes
  rentrez
  reshape2
  rio
  rmarkdown
  rms
  rsvg
  sass
  scales
  sctransform
  shiny
  shinycssloaders
  shinydashboard
  shinyjs
  stringi
  stringr
  survival
  survivalROC
  survminer
  tidyr
  tidyverse
  tiff
  timeROC
  visNetwork
  webshot2
  writexl
  xgboost
  xml2
  zip
]
