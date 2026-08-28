{ den, ... }:
{
  den.aspects."9router" = {
    includes = [ den.aspects.secretspec ];

    nixos =
      { config, pkgs, ... }:
      let
        secret = description: field: {
          inherit description;
          delivery = "envvar";
          owner = "root";
          group = "root";
          services = [ "9router" ];
          ref = {
            item = "9router";
            inherit field;
          };
        };
      in
      {
        imports = [ ../../../packages/9router/module.nix ];

        services.secretspec = {
          enable = true;
          providers.op = {
            type = "onepassword";
            uri = "onepassword+token://Infrastructure";
            credentialFiles.OP_SERVICE_ACCOUNT_TOKEN = "/etc/opnix-token";
            packages = [ pkgs._1password-cli ];
            secrets = {
              INITIAL_PASSWORD = secret "9Router initial password" "initial-password";
              JWT_SECRET = secret "9Router JWT signing secret" "jwt-secret";
              API_KEY_SECRET = secret "9Router API-key signing secret" "api-key-secret";
              MACHINE_ID_SALT = secret "9Router machine-ID salt" "machine-id-salt";
            };
          };
        };

        services."9router" = {
          enable = true;
          environmentFiles = [ config.services.secretspec.scopeExportPath."9router" ];
        };

        systemd.services."9router" = {
          after = [ "secretspec-secrets.service" ];
          requires = [ "secretspec-secrets.service" ];
        };
      };
  };
}
