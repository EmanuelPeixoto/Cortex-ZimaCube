{
  home = {
    homeDirectory = "/home/zimacube";
    username = "zimacube";

    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "ghostty";
    };
  };

  programs.home-manager.enable = true;
}
