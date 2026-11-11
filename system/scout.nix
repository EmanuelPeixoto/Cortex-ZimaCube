# RCDome Scout — rodagem mensal do professor medina (scout.timer).
# O pipeline (scout_runner.py + venv + dados) vive fora do repo, em scoutDir.
#
# PENDENTE: o pi é chamado sem allowlist de ferramentas (read/bash/edit/write) sobre
# conteúdo não confiável. Ver docs/security.md e docs/containerization.md do pi;
# o ajuste pontual é `--tools <allowlist>` em invoke_agent (scout_runner.py).
{ config, ... }:
let
  profHome = "/mnt/sharefiles/medina";
  scoutDir = "${profHome}/students/aluno0549-6/RCDome/RCDome_scout";
  logFile = "${scoutDir}/scout_cron.log";
in
{
  systemd.services.scout = {
    description = "RCDome Scout monthly surveillance";

    wants = [ "mnt-sharefiles.mount" ];
    after = [ "mnt-sharefiles.mount" "remote-fs.target" ];

    # systemd não herda /run/current-system/sw/bin: sem isto o runner não acha `pi`.
    path = [ config.system.path ];

    serviceConfig = {
      Type = "oneshot";
      User = "medina";
      WorkingDirectory = scoutDir;
      ExecStart = "${profHome}/scout-venv/bin/python3 -u scout_runner.py";
      StandardOutput = "append:${logFile}";
      StandardError = "append:${logFile}";

      # Teto por rodada: 6 h (alinhar com agent_timeout_seconds do scout_config.json).
      TimeoutStartSec = "6h";
      TimeoutStopSec = "30s";

      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict"; # /, /etc, /nix/store read-only...
      ProtectHome = "read-only";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectProc = "invisible";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      UMask = "0077";

      ReadWritePaths = [
        scoutDir                      # entregáveis, checkpoint, discovery_matrix, log
        "${profHome}/.pi"             # sessões/auth do pi (agents/…)
        "-${profHome}/.cache"         # "-" = ignora se não existir
        "-${profHome}/.config"
        "-${profHome}/.local"
      ];

      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];

      MemoryMax = "16G";
      CPUQuota = "400%";
    };

    # Sem `wantedBy`: só o timer abaixo inicia a unit (nada de rodar no boot).
  };

  systemd.timers.scout = {
    description = "Run RCDome Scout on the 1st of each month";
    timerConfig = {
      OnCalendar = "*-*-01 09:00:00";
      Persistent = true; # máquina desligada no dia 1º -> roda na próxima vez que ligar
    };
    wantedBy = [ "timers.target" ];
  };
}
