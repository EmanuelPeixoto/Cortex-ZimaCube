{
  programs.git = {
    enable = true;

    settings = {
      user = {
        email = "leunamepeixoto@gmail.com";
        name = "EmanuelPeixoto";
      };

      github = {
        User = "EmanuelPeixoto";
      };

      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
    options.display = "side-by-side-show-both";
  };
}
