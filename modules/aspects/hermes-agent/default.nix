{ den, inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
  };

  den.aspects.hermes-agent = {
    includes = [ den.aspects.opnix ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        package = pkgs.callPackage ../../../packages/hermes-agent {
          inherit (llmPkgs) hermes-agent;
        };
      in
      {
        imports = [ ../../../packages/hermes-agent/module.nix ];

        nixpkgs.config.permittedInsecurePackages = [
          # libolm is used by the Hermes Matrix client.
          "olm-3.2.16"
        ];

        services.onepassword-secrets = {
          enable = true;
          secrets = {
            matrixBotEnv = {
              reference = "op://Infrastructure/matrix-bot/hermes";
              owner = config.services.hermes-agent.user;
              group = config.services.hermes-agent.group;
              mode = "0600";
              services = [ "hermes-agent" ];
            };
            matrixRecoveryKey = {
              reference = "op://Infrastructure/matrix-bot/security-key";
              owner = config.services.hermes-agent.user;
              group = config.services.hermes-agent.group;
              mode = "0600";
              services = [ "hermes-agent" ];
            };
            openrouterAgentEnv = {
              reference = "op://Infrastructure/openrouter-agent/hermes";
              owner = config.services.hermes-agent.user;
              group = config.services.hermes-agent.group;
              mode = "0400";
              services = [ "hermes-agent" ];
            };
          };
        };

        services.hermes-agent = {
          inherit package;

          enable = true;
          addToSystemPackages = true;
          settings = {
            memory = {
              group_sessions_per_user = true;
              memory_enabled = true;
              user_profile_enabled = true;
            };
            model.default = "inception/mercury-2";
          };
          environment = {
            MATRIX_ALLOWED_USERS = "@rcorrear:matrix.org";
            MATRIX_ENCRYPTION = "true";
            MATRIX_HOMESERVER = "https://matrix.org";
          };
          environmentFiles = [
            config.services.onepassword-secrets.secretPaths.matrixBotEnv
          ];
        };

        systemd.services.hermes-agent = {
          after = [ "opnix-secrets.service" ];
          requires = [ "opnix-secrets.service" ];
          preStart = lib.mkAfter ''
            printf '\nMATRIX_RECOVERY_KEY=%s\n' "$(${pkgs.coreutils}/bin/cat ${config.services.onepassword-secrets.secretPaths.matrixRecoveryKey})" >> ${config.services.hermes-agent.stateDir}/.hermes/.env
            printf 'OPENROUTER_API_KEY=%s\n' "$(${pkgs.coreutils}/bin/cat ${config.services.onepassword-secrets.secretPaths.openrouterAgentEnv})" >> ${config.services.hermes-agent.stateDir}/.hermes/.env
          '';
        };
      };
  };
}
