# Keyring do GNOME desligado: o "login keyring" local não abre com a senha atual e
# o prompt reaparecia em qualquer desktop. Sem o daemon não existe o serviço D-Bus
# org.freedesktop.secrets, então nada pede senha (libsecret cai no storage do app).
# Para voltar: remova o import em ./default.nix; no próximo login o keyring é
# recriado com a senha atual (mantenha em sincronia trocando com `passwd`).
{ lib, ... }:
{
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  # O módulo liga pam_gnome_keyring no serviço "login" (base do lightdm).
  security.pam.services.login.enableGnomeKeyring = lib.mkForce false;
  security.pam.services.lightdm.enableGnomeKeyring = lib.mkForce false;
}