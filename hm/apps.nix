{ pkgs, ... }:
let
  catfolder = import ./scripts/catfolder.nix { inherit pkgs; };
  motd = import ./scripts/motd.nix { inherit pkgs; };
  yt-tlp-menu = import ./scripts/yt-dlp-menu.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    catfolder
    motd
    yt-tlp-menu

    audacity                  # Sound editor with graphical UI
    curl                      # Command line tool for transferring files with URL syntax
    exfatprogs                # exFAT filesystem userspace utilities
    ffmpeg                    # Complete, cross-platform solution to record, convert and stream audio and video
    gcc                       # GNU Compiler Collection
    gdb                       # GNU Project debugger
    gh                        # GitHub CLI tool
    gimp                      # GNU Image Manipulation Program
    glibc                     # GNU C Library
    gnumake                   # Tool to control the generation of non-source files from sources
    gparted                   # Graphical disk partitioning tool
    iftop                     # Display bandwidth usage on a network interface
    inetutils                 # Collection of common network programs
    iw                        # Tool to use nl80211
    jmtpfs                    # FUSE filesystem for MTP devices like Android phones
    killall                   # No description :/
    lazygit                   # Simple terminal UI for git commands
    libmtp                    # Implementation of Microsoft's Media Transfer Protocol
    libreoffice               # Comprehensive, professional-quality productivity suite, a variant of openoffice.org
    lm_sensors                # Tools for reading hardware sensors
    lshw                      # Provide detailed information on the hardware configuration of the machine
    ncdu                      # Disk usage analyzer with an ncurses interface
    nload                     # Monitors network traffic and bandwidth usage with ncurses graphs
    nomacs                    # Qt-based image viewer
    pciutils                  # Collection of programs for inspecting and manipulating configuration of PCI devices
    progress                  # Tool that shows the progress of coreutils programs
    speedtest-cli             # Command line interface for testing internet bandwidth using speedtest.net
    unrar                     # Utility for RAR archives
    unzip                     # Extraction utility for archives compressed in .zip format
    usbutils                  # Tools for working with USB devices, such as lsusb
    vlc                       # Cross-platform media player and streaming server
    wget                      # Tool for retrieving files using HTTP, HTTPS, and FTP
    wl-clipboard              # Command-line copy/paste utilities for Wayland
    yt-dlp                    # Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)
    zathura                   # Highly customizable and functional PDF viewer
    zip                       # Compressor/archiver for creating and modifying zipfiles
  ];
}
