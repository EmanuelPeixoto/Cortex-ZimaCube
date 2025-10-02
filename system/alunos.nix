{ pkgs, lib, ... }:

let
  # formato: nome_professor = [ "matricula1" "matricula2" ];
  professoresETurmas = {
    professor = [ "2025001" "2025002" "2025003" ];
  };

  baseDir = "/mnt/nextcloud";


  allUsers = lib.listToAttrs (
    lib.flatten (lib.attrsets.mapAttrsToList (
      professorName: matriculas:
      let
        professorUser = {
          name = professorName;
          value = {
            isSystemUser = true;
            group = professorName;
            createHome = false;
            home = "${baseDir}/${professorName}";
            shell = pkgs.fish;
            extraGroups = [ "${professorName}-group" "wheel" ];
          };
        };

        studentUsers = lib.map (matricula:
          let usuarioCompleto = "aluno" + matricula;
          in {
            name = usuarioCompleto;
            value = {
              isSystemUser = true;
              group = usuarioCompleto;
              createHome = false;
              home = "${baseDir}/${professorName}/students/${usuarioCompleto}";
              shell = pkgs.fish;
              extraGroups = [ "${professorName}-group" ];
              initialPassword = usuarioCompleto;
            };
          }) matriculas;
      in
        [ professorUser ] ++ studentUsers
    ) professoresETurmas)
  );

  allGroups = lib.mapAttrs' (professorName: _:
    lib.nameValuePair "${professorName}-group" {
      members = [ "rstudio-server" "sftpgo" ];
    }
  ) professoresETurmas;

  allPrivateGroups = lib.genAttrs (lib.attrNames allUsers) (_: {});

in
{
  users = {
    users = {
      sftpgo = { isSystemUser = true; group = "sftpgo"; };
    } // allUsers;

    groups = {
      sftpgo = {};
    } // allGroups // allPrivateGroups;
  };

  environment.systemPackages = with pkgs; [ acl coreutils ];

  systemd.services."setup-data-dirs-and-acls" = {
    description = "Create user directories and set POSIX ACLs for academic users";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "sftpgo.service" "nss-user-lookup.target" ];
    requires = [ "nss-user-lookup.target" ];
    path = with pkgs; [ coreutils acl ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      RemainAfterExit = true;
    };
    script = ''
      set -eux

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (professorName: matriculas:
          let
            usuariosAlunos = lib.map (m: "aluno" + m) matriculas;
            studentList = lib.concatStringsSep " " usuariosAlunos;
            professorGroup = "${professorName}-group";
          in ''
            echo "--- Configurando para o professor: ${professorName} ---"

            PROF_HOME="${baseDir}/${professorName}"
            STUDENTS_BASE_DIR="$PROF_HOME/students"
            SHARED_DIR="$PROF_HOME/Publico"
            PROF_GROUP="${professorGroup}"

            mkdir -p "$STUDENTS_BASE_DIR" "$SHARED_DIR"
            chown -R "${professorName}:$PROF_GROUP" "$PROF_HOME"
            chmod -R 770 "$PROF_HOME"
            chmod g+s "$PROF_HOME" "$STUDENTS_BASE_DIR" "$SHARED_DIR"

            setfacl -R -m u:${professorName}:rwx,g:$PROF_GROUP:rwx,u:sftpgo:rwx "$SHARED_DIR"
            setfacl -R -d -m u:${professorName}:rwx,g:$PROF_GROUP:rwx,u:sftpgo:rwx "$SHARED_DIR"

            for usuario in ${studentList}; do
              STUD_HOME="$STUDENTS_BASE_DIR/$usuario"
              mkdir -p "$STUD_HOME"
              chown -R "$usuario:$PROF_GROUP" "$STUD_HOME"
              chmod 770 "$STUD_HOME"
              setfacl -b "$STUD_HOME"
              setfacl -m u:$usuario:rwx,u:${professorName}:rwx,u:sftpgo:rwx,u:rstudio-server:rwx,o::--- "$STUD_HOME"
              setfacl -d -m u:$usuario:rwx,u:${professorName}:rwx,u:sftpgo:rwx,u:rstudio-server:rwx,o::--- "$STUD_HOME"
            done
          ''
        ) professoresETurmas
      )}
      echo ">>> Configuração de diretórios e ACLs concluída com sucesso. <<<"
    '';
  };
}
