# Keyring do GNOME desligado.
#
# Motivo: o "login keyring" pede senha que não é a de login (nem a antiga). O
# arquivo era de 09/2025, foi recriado em 27/10 às 12:18 (sessão antiga do daemon
# o reescreveu depois de apagado) e, testado hoje, NÃO abre com a senha atual:
#   $ printf '<senha-atual>\n' | gnome-keyring-daemon --unlock --components=secrets
#   $ busctl --user get-property ... Collection Locked  ->  b true
# Ou seja: o prompt ia continuar aparecendo em qualquer desktop (não é coisa do
# Cinnamon nem do XFCE).
#
# Sem o daemon não existe o serviço D-Bus org.freedesktop.secrets: nenhum app tem
# o que desbloquear e nada pede senha.
#
# Efeito colateral (aceito): quem usava libsecret passa a guardar o segredo no
# próprio arquivo do app, sem criptografia de keyring.
#   - Wi-Fi: /etc/NetworkManager/system-connections/*.nmconnection (600, root)
#   - Chromium/Chrome: password store "basic" (ofuscado, não criptografado)
#   - Firefox/Zen: não muda nada (usa NSS próprio)
#
# Para VOLTAR: apague este arquivo + o import em ./default.nix, troque a sessão e
# no próximo login o keyring é recriado com a senha atual (aí mantém-se em sincronia
# desde que a senha seja trocada com `passwd`, que atualiza o keyring via PAM).
{ lib, ... }:
{
  # XFCE (como o Cinnamon) liga isso com mkDefault true.
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  # O módulo do gnome-keyring liga o pam_gnome_keyring no serviço "login", que é a
  # base do /etc/pam.d/lightdm (auth/session substack login).
  security.pam.services.login.enableGnomeKeyring = lib.mkForce false;
  security.pam.services.lightdm.enableGnomeKeyring = lib.mkForce false;
}
