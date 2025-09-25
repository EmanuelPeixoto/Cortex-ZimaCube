{ pkgs, lib, ... }:
let
  professorName = "professor";

  matriculas = [
    "2025001"
    "2025002"
    "2025003"
  ];

  mkAluno = matricula: {
    shell = pkgs.fish;
    createHome = false;
    isNormalUser = true;
    extraGroups = [ "nextcloud" ];
    description = "Aluno ${matricula}";
    initialPassword = matricula;
    home = "/mnt/nextcloud/data/${professorName}/files/${matricula}";
  };

  alunos = lib.genAttrs matriculas mkAluno;
in
{
  users = {
    users = {
      ${professorName} = {
        shell = pkgs.fish;
        isNormalUser = true;
        createHome = true;
        home = "/mnt/nextcloud/data/${professorName}";
        extraGroups = [ "nextcloud" "professor-group" ];
      };
    } // alunos;

    groups.professor-group = { };
  };

  # Cria diretórios básicos
  systemd.tmpfiles.rules = [
    "d /mnt/nextcloud/${professorName} 0750 ${professorName} professor-group -"
  ] ++ map (matricula:
    "d /mnt/nextcloud/${professorName}/files/${matricula} 0770 ${matricula} ${matricula} -"
  ) matriculas;

  # Aplica ACL para garantir acesso do professor (ZFS)
  systemd.services."set-acl-alunos" = {
    description = "Set ZFS ACLs for alunos and professor";
    after = [ "local-fs.target" "nextcloud-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "set-zfs-acl" ''
        set -e
        for user in ${lib.concatStringsSep " " matriculas}; do
          dir="/mnt/nextcloud/${professorName}/files/$user"

          # Garante que o diretório existe
          mkdir -p "$dir"

          # Dono é o aluno
          chown $user:$user "$dir"

          # Permissão base restrita
          chmod 700 "$dir"

          # Configura ZFS ACL mode e inherit
          zfs set aclmode=passthrough nextcloud
          zfs set aclinherit=passthrough nextcloud

          # Aplica ACEs: aluno tem full, professor full, nextcloud full
          chmod A+user:$user:full_set:allow "$dir"
          chmod A+user:${professorName}:full_set:allow "$dir"
          chmod A+user:nextcloud:full_set:allow "$dir"
        done
      '';
    };
  };
}
