{ pkgs, lib, ... }:

let
  # formato: nome_professor = [ "matricula1" "matricula2" ];
  professoresETurmas = {
    medina = [ "0549-6" "202512120026" "202412220014" "20211210030" "202412120031" "521-5" "ccemanuel" ];
  };

  baseDir = "/mnt/sharefiles";


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
            initialPassword = professorName;
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
    after = [ "nss-user-lookup.target" ];
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

          mkdir -p "$STUDENTS_BASE_DIR" "$SHARED_DIR"
          chown -R "${professorName}:${professorName}" "$PROF_HOME"
          chmod 750 "$PROF_HOME"
          chmod g+s "$PROF_HOME" "$STUDENTS_BASE_DIR" "$SHARED_DIR"

          # Pasta compartilhada do professor
          chown "${professorName}:${professorName}" "$SHARED_DIR"
          chmod 770 "$SHARED_DIR"

          for usuario in ${studentList}; do
            STUD_HOME="$STUDENTS_BASE_DIR/$usuario"
            mkdir -p "$STUD_HOME"

            # Dono e grupo: o próprio aluno
            chown -R "$usuario:$usuario" "$STUD_HOME"
            chmod 700 "$STUD_HOME" # apenas o aluno tem acesso

            # ACL: o professor também pode ler e escrever
            setfacl -b "$STUD_HOME"
            setfacl -m u:${professorName}:rwx "$STUD_HOME"
            setfacl -d -m u:${professorName}:rwx "$STUD_HOME"
          done
          ''
        ) professoresETurmas
      )}
    echo ">>> Configuração concluída com sucesso. <<<"
    '';
  };
}
