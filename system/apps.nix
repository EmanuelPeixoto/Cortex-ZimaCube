{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    btop-cuda                 # Monitor of resources
    curl                      # Command line tool for transferring files with URL syntax
    fish                      # Smart and user-friendly command line shell
    gcc                       # GNU Compiler Collection
    gdb                       # GNU Project debugger
    gh                        # GitHub CLI tool
    git                       # Distributed version control system
    glibc                     # GNU C Library
    gnumake                   # Tool to control the generation of non-source files from sources
    killall                   # No description :/
    lazygit                   # Simple terminal UI for git commands
    neovim                    # Vim text editor fork focused on extensibility and agility
    nh                        # Yet another nix cli helper
    nix-output-monitor        # Processes output of Nix commands to show helpful and pretty information
    progress                  # Tool that shows the progress of coreutils programs
    unrar                     # Utility for RAR archives
    unzip                     # Extraction utility for archives compressed in .zip format
    usbutils                  # Tools for working with USB devices, such as lsusb
    vlc                       # Cross-platform media player and streaming server
    wget                      # Tool for retrieving files using HTTP, HTTPS, and FTP
    yazi                      # Blazing fast terminal file manager written in Rust, based on async I/O
    zip                       # Compressor/archiver for creating and modifying zipfiles
  ];
}
