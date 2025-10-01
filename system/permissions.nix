{ pkgs, lib, ... }:

let
  professorName = "professor";
  baseDir = "/mnt/nextcloud";
  matriculas = [ "2025001" "2025002" "2025003" ];
  usuariosAlunos = lib.map (matricula: "aluno" + matricula) matriculas;

in
{
  environment.systemPackages = with pkgs; [ acl coreutils ];
  systemd.services."setup-data-dirs-and-acls" = {
    description = "Create user directories for SFTPGo/RStudio and set POSIX ACLs";
    wantedBy = [ "multi-user.target" ];

    # Dependências corretas do systemd.
    after = [ "network-online.target" "sftpgo.service" "nss-user-lookup.target" ];
    requires = [ "nss-user-lookup.target" "sftpgo.service" ];

    script = let
      studentList = lib.concatStringsSep " " usuariosAlunos;
    in ''
      set -eux

      PROF_HOME="${baseDir}/${professorName}"
      STUDENTS_BASE_DIR="$PROF_HOME/students"
      SHARED_DIR="$PROF_HOME/Publico"

      mkdir -p "$STUDENTS_BASE_DIR" "$SHARED_DIR"
      chown -R "${professorName}:professor-group" "$PROF_HOME"
      chmod 770 "$PROF_HOME"

      setfacl -R -m u:${professorName}:rwx,g:professor-group:rwx,u:sftpgo:rwx "$SHARED_DIR"
      setfacl -R -m d:u:${professorName}:rwx,d:g:professor-group:rwx,d:u:sftpgo:rwx "$SHARED_DIR"

      # ✅ ✅ ✅ CORREÇÃO FINAL DA SINTAXE DO LAÇO 'FOR' ✅ ✅ ✅
      for usuario in ${studentList}; do
        STUD_HOME="$STUDENTS_BASE_DIR/$usuario"
        mkdir -p "$STUD_HOME"
        chown -R "$usuario:professor-group" "$STUD_HOME"
        chmod 770 "$STUD_HOME"
        setfacl -b "$STUD_HOME"
        setfacl -m u:$usuario:rwx,u:${professorName}:rwx,u:sftpgo:rwx,u:rstudio-server:rwx,o::--- "$STUD_HOME"
        setfacl -d -m u:$usuario:rwx,u:${professorName}:rwx,u:sftpgo:rwx,u:rstudio-server:rwx,o::--- "$STUD_HOME"
      done

      echo "ACLs para SFTPGo e RStudio aplicadas com sucesso."
    '';
    path = with pkgs; [ coreutils acl ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      RemainAfterExit = false;
    };
  };
}
