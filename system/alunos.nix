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
    after = [ "nss-user-lookup.target" "remote-fs.target" ];
    requires = [ "nss-user-lookup.target" "remote-fs.target" ];
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

          # torne o dono do diretório do professor o próprio professor
          # e o grupo do diretório como ${professorName}-group (para que alunos no grupo possam transitar)
          # ATENÇÃO: NÃO usar -R no PROF_HOME — isso invadiria os diretórios dos alunos e trocaria o dono
          # Em vez disso, aplica ownership recursivo só nos itens do professor, pulando students/
          chown "${professorName}:${professorName}-group" "$PROF_HOME"
          for item in "$PROF_HOME"/*; do
            [ "$item" = "$STUDENTS_BASE_DIR" ] && continue
            chown -R "${professorName}:${professorName}-group" "$item" || true
          done
          chmod 750 "$PROF_HOME"
          chmod g+s "$PROF_HOME" "$STUDENTS_BASE_DIR" "$SHARED_DIR"

          # Pasta compartilhada do professor
          chown "${professorName}:${professorName}-group" "$SHARED_DIR"
          chmod 750 "$SHARED_DIR"
          # ACL: garante que arquivos novos/existentes sejam legíveis pelo grupo (alunos)
          setfacl -m g:${professorGroup}:rx "$SHARED_DIR"
          setfacl -d -m g:${professorGroup}:rx "$SHARED_DIR"

          for usuario in ${studentList}; do
            STUD_HOME="$STUDENTS_BASE_DIR/$usuario"
            mkdir -p "$STUD_HOME"

            # Dono e grupo: o próprio aluno (recursivo para corrigir arquivos existentes)
            chown -R "$usuario:$usuario" "$STUD_HOME"
            chmod 700 "$STUD_HOME" # apenas o aluno tem acesso

            # ACL: o professor também pode ler e escrever (recursivo para arquivos existentes)
            setfacl -R -m u:${professorName}:rwx "$STUD_HOME"
            setfacl -d -m u:${professorName}:rwx "$STUD_HOME"
          done
          ''
        ) professoresETurmas
      )}
    echo ">>> Configuração concluída com sucesso. <<<"
    '';
  };
}
