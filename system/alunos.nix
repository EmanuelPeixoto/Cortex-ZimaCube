{ pkgs, lib, ... }:

let
  # formato: nome_professor = [ "matricula1" "matricula2" ];
  professoresETurmas = {
    medina = [ "0549-6" "202512120026" "202412220014" "20211210030" "202412120031" "521-5" "ccemanuel" ];
  };

  # Re-aplica dono + ACL do professor (rode com sudo após mover arquivos via mv/root).
  fixAlunoPerms = pkgs.writeShellScriptBin "fix-aluno-perms" ''
    set -euo pipefail
    [ "$#" -eq 2 ] || { echo "uso: sudo fix-aluno-perms <professor> <aluno>"; exit 1; }
    P="$1"; A="$2"
    D="/mnt/sharefiles/$P/students/$A"
    [ -d "$D" ] || { echo "dir $D não existe"; exit 1; }
    chown -R "$A:$A" "$D"
    setfacl -R -m u:"$P":rwx "$D"
    setfacl -m u:"$P":rwx "$D"
    setfacl -d -m u:"$P":rwx "$D"
    echo "ok: $D"
  '';

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
      members = [ "rstudio-server" ];
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

  environment.systemPackages = with pkgs; [ acl coreutils fixAlunoPerms ];

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

    # O recursivo (lento) roda só UMA vez; depois o setgid + ACL default cuidam dos arquivos novos.
    PERMS_MARKER="${baseDir}/.perms-initialized"

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
          if [ ! -f "$PERMS_MARKER" ]; then
            for item in "$PROF_HOME"/*; do
              [ "$item" = "$STUDENTS_BASE_DIR" ] && continue
              chown -R "${professorName}:${professorName}-group" "$item" || true
            done
          fi
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

            # rápido (sempre): dono/ACL do diretório + default ACL p/ arquivos novos
            chown "$usuario:$usuario" "$STUD_HOME"
            chmod 700 "$STUD_HOME" # apenas o aluno tem acesso
            setfacl -m u:${professorName}:rwx "$STUD_HOME"
            setfacl -d -m u:${professorName}:rwx "$STUD_HOME"

            # recursivo (só 1ª vez): corrige arquivos já existentes
            if [ ! -f "$PERMS_MARKER" ]; then
              chown -R "$usuario:$usuario" "$STUD_HOME"
              setfacl -R -m u:${professorName}:rwx "$STUD_HOME"
            fi
          done
          ''
        ) professoresETurmas
      )}
    touch "$PERMS_MARKER"
    echo ">>> Configuração concluída com sucesso. <<<"
    '';
  };
}
