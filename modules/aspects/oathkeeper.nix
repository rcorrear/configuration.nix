{ den, inputs, ... }:
let
  oathkeeperMicrovm = import ../../packages/oathkeeper/microvm.nix { inherit inputs; };
  secretDir = "/run/oathkeeper-secrets";
  sessionCheckUrlMarker = "https://__OATHKEEPER_SESSION_CHECK_URL__/sessions/whoami";
  upstreamUrlMarker = "__OATHKEEPER_UPSTREAM_URL__";
in
{
  flake-file.inputs.microvm = {
    url = "github:microvm-nix/microvm.nix/174e28de151e069a95d03c86dd174c3b71bdfba7";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake = {
    lib = {
      inherit (oathkeeperMicrovm) mkOathkeeperMicrovm mkOathkeeperMicrovmModule;
      oathkeeperService =
        pkgs:
        inputs.nixpkgs.lib.modules.importApply ../../packages/oathkeeper/service.nix { inherit pkgs; };
    };
    nixosModules = {
      microvm-host = inputs.microvm.nixosModules.host;
      oathkeeper = import ../../packages/oathkeeper/module.nix;
    };
  };

  den.aspects.oathkeeper = {
    includes = [ den.aspects.secretspec ];

    nixos =
      { config, pkgs, ... }:
      {
        imports = [ inputs.microvm.nixosModules.host ];

        services.secretspec = {
          enable = true;
          providers.op = {
            type = "onepassword";
            uri = "onepassword+token://Infrastructure";
            credentialFiles.OP_SERVICE_ACCOUNT_TOKEN = config.services.onepassword-secrets.tokenFile;
            packages = [ pkgs._1password-cli ];
            secrets = {
              oathkeeperSessionCheckHost = {
                description = "Oathkeeper Ory session-check host";
                delivery = "file";
                path = "${secretDir}/session-check-host";
                ref = {
                  item = "oathkeeper";
                  field = "session-check-host";
                };
              };
              oathkeeperUpstreamUrl = {
                description = "Oathkeeper upstream URL";
                delivery = "file";
                path = "${secretDir}/upstream-url";
                ref = {
                  item = "oathkeeper";
                  field = "upstream-url";
                };
              };
            };
          };
        };

        systemd.tmpfiles.rules = [
          "d ${secretDir} 0700 root root -"
        ];

        systemd.services."microvm-virtiofsd@oathkeeper" = {
          after = [ "secretspec-secrets.service" ];
          requires = [ "secretspec-secrets.service" ];
        };

        microvm = {
          host.enable = true;
          vms.oathkeeper.config = oathkeeperMicrovm.mkOathkeeperMicrovmModule {
            sessionCheckUrl = sessionCheckUrlMarker;
            upstreamUrl = upstreamUrlMarker;
            extraModules = [
              (import ../../packages/oathkeeper/runtime-secrets.nix {
                inherit secretDir sessionCheckUrlMarker upstreamUrlMarker;
              })
              {
                microvm.shares = [
                  {
                    mountPoint = secretDir;
                    proto = "virtiofs";
                    readOnly = true;
                    source = secretDir;
                    tag = "oathkeeper-secrets";
                  }
                ];
              }
            ];
          };
          autostart = [ "oathkeeper" ];
        };
      };
  };
}
