{
  services.sftpgo = {
    enable = true;
    user = "sftpgo";
    group = "sftpgo";

    settings = {
      httpd = {
        bindings = [{ port = 8080; address = "0.0.0.0"; }];
      };
      sftpd = {
        bindings = [{ port = 2022; address = "0.0.0.0"; }];
      };
      data_provider = {
        # Usando o banco de dados padrão, que é suficiente para começar
        name = "sqlite";
        # O NixOS gerencia o path automaticamente
      };
      common = {
        # O SFTPGo criará as homes dos usuários de sistema aqui
        # Esta diretiva não é necessária se os usuários já existem no sistema
        # A home já é definida no módulo `users.users` em alunos.nix
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
