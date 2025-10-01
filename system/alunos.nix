{ pkgs, lib, ... }:

let
  professorName = "professor";
  baseDir = "/mnt/nextcloud";
  matriculas = [ "2025001" "2025002" "2025003" ];
  usuariosAlunos = lib.map (matricula: "aluno" + matricula) matriculas;

in
{
  users = {
    users = {
      sftpgo = { isSystemUser = true; group = "sftpgo"; };

      ${professorName} = {
        isNormalUser = true;
        createHome = false;
        home = "${baseDir}/${professorName}";
        shell = pkgs.fish;
        extraGroups = [ "professor-group" "wheel" ];
      };

    } // (lib.genAttrs usuariosAlunos (usuarioCompleto: {
      isNormalUser = true;
      createHome = false;
      home = "${baseDir}/${professorName}/students/${usuarioCompleto}";
      shell = pkgs.fish;
      extraGroups = [ "professor-group" ];
      initialPassword = "${usuarioCompleto}";
    }));

    groups = {
      sftpgo = {};
      "professor-group" = {
        # ✅ CORREÇÃO FINAL: Adiciona o usuário 'sftpgo' ao grupo.
        members = [ "rstudio-server" "sftpgo" ];
      };
    };
  };
}
