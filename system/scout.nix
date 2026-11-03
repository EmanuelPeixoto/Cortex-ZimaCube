# RCDome Scout — rodagem mensal do professor medina.
#
# Origem: bloco que ele adicionou em /etc/nixos/configuration.nix (22/10/2026, logo
# depois do `system.stateVersion`). Aquele arquivo NÃO é usado neste sistema — o
# build vem do flake em ~/.config/Cortex-ZimaCube, então o serviço nunca existiu
# ("Unit scout.timer could not be found"). O que está abaixo é o mesmo pipeline,
# com as correções para rodar como serviço de sistema + hardening.
#
# ── Diferenças em relação ao original ───────────────────────────────────────────
#   1. `path = [ config.system.path ]` — serviços systemd no NixOS NÃO herdam
#      /run/current-system/sw/bin no PATH, e o runner chama `shutil.which("pi")`.
#      Sem isso: "pi: command not found".
#   2. `Type = "oneshot"` — o scout_runner.py roda a tarefa e termina.
#   3. `after`/`wants` do mount /mnt/sharefiles (ZFS), onde ficam venv/script/dados.
#   4. SEM `wantedBy = [ "multi-user.target" ]`: no original o serviço rodava no
#      boot E a cada `nixos-rebuild switch`, ou seja, uma rodada completa do agente
#      (até 24 h, API DeepSeek paga) a cada reboot. Aqui só o timer dispara.
#      Rodada manual continua possível: `sudo systemctl start scout.service`.
#   5. Hardening: `ProtectSystem = "strict"` + `ReadWritePaths` (só o diretório do
#      scout e o estado do pi ficam graváveis), `NoNewPrivileges` (mata sudo dentro
#      do serviço), rede só INET/INET6/UNIX, sem devices, /tmp privado, limites de
#      memória/CPU e teto de 6 h por rodada.
#
# ── PENDÊNCIA (não resolvida aqui de propósito) ─────────────────────────────────
# O ponto 5 não resolve o risco principal: o `pi` é chamado sem allowlist de
# ferramentas, então o agente tem `read/bash/edit/write` e, sem supervisão, processa
# texto de paper/preprint (conteúdo não confiável). A própria doc do pi diz
# (docs/security.md): "No built-in sandbox... Prompt injection from repository files,
# comments, documentation, context files, or build output is expected local-agent
# risk and cannot be reliably prevented by pi." Sugestões, em ordem de custo:
#   a) restringir ferramentas do agente: em /mnt/sharefiles/medina/.pi/agent/
#      settings.json usar "defaultTools": [] (ou só o mínimo que o runner precisa),
#      ou passar `--tools <allowlist>` na linha de comando do pi (scout_runner.py,
#      função invoke_agent);
#   b) `--no-approve` / `defaultProjectTrust` para o agente não carregar extensões
#      do diretório do projeto;
#   c) ideal: rodar o pi em container/sandbox (docs/containerization.md do pi),
#      com credenciais só de saída e o diretório do scout montado.
# Também vale alinhar `agent_timeout_seconds` em scout_config.json (hoje 86400 = 24 h)
# para <= 21600 (6 h), igual ao TimeoutStartSec abaixo: assim o runner aborta de
# forma limpa (returncode 124, checkpoint preservado) em vez de levar SIGKILL.
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

    # `pi` vem do profile do sistema (system/ia.nix, input llm-agents).
    path = [ config.system.path ];

    serviceConfig = {
      Type = "oneshot";
      User = "medina";
      WorkingDirectory = scoutDir;
      ExecStart = "${profHome}/scout-venv/bin/python3 -u scout_runner.py";
      # mantém o log que ele já lê (o runner também grava scout_run_log.jsonl)
      StandardOutput = "append:${logFile}";
      StandardError = "append:${logFile}";

      # Teto por rodada: 6 h (ver a pendência sobre agent_timeout_seconds acima).
      TimeoutStartSec = "6h";
      TimeoutStopSec = "30s";

      # ── Sandbox ──────────────────────────────────────────────────────────────
      NoNewPrivileges = true; # nada de setuid/sudo a partir do serviço
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

      # ...exceto estes caminhos (o resto do filesystem é read-only).
      ReadWritePaths = [
        scoutDir                      # entregáveis, checkpoint, discovery_matrix, log
        "${profHome}/.pi"             # sessões/auth do pi (agents/…)
        "-${profHome}/.cache"         # "-" = ignora se não existir
        "-${profHome}/.config"
        "-${profHome}/.local"
      ];

      # Só rede de verdade; sem sockets de device/etc.
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
