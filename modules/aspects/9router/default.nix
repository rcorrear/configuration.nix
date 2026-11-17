{ den, ... }:
{
  den.aspects."9router-service" = {
    includes = [ den.aspects.secretspec ];

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      let
        tailscale = import ../../../packages/tailscale-service-gateway/command.nix {
          inherit pkgs;
          package = config.services.tailscale.package;
        };
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

        services = {
          secretspec = {
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

          "9router" = {
            enable = true;
            environmentFiles = [ config.services.secretspec.scopeExportPath."9router" ];
          };

          tailscale.enable = true;
        };

        # Ordinary Serve uses the dedicated guest's Tailscale identity.
        # Keep the backend on loopback; Tailscale terminates HTTPS on port 443.
        # The declarative module manages named Services, not node-level Serve.
        # See docs/9router.md for upstream PRs to revisit before replacing this unit.
        systemd.services."9router-tailscale" = {
          description = "Tailscale Serve for 9Router";
          wantedBy = [
            "multi-user.target"
            "tailscaled.service"
            "9router.service"
          ];
          after = [
            "tailscaled.service"
            "tailscaled-autoconnect.service"
            "9router.service"
          ];
          requires = [
            "tailscaled.service"
            "9router.service"
          ];
          partOf = [
            "tailscaled.service"
            "9router.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${tailscale} serve --bg --yes --https=443 http://127.0.0.1:${
              toString config.services."9router".port
            }";
            ExecStop = "${tailscale} serve --yes --https=443 off";
            Restart = "on-failure";
            RestartSec = "10s";
          };
        };

        systemd.services."9router" = {
          after = [ "secretspec-secrets.service" ];
          requires = [ "secretspec-secrets.service" ];
        };
      };
  };
}
