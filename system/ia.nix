{ inputs, pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    loadModels = [ "qwen3:14b" ];
  };
  environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    pi
  ]++[
      pkgs.nodejs_22
      pkgs.goose-cli
  ];
}
