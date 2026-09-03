{ den, inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
  };

  den.aspects.hermes-agent = {
    includes = [ den.aspects.secretspec ];

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      let
        llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        package = pkgs.callPackage ../../../packages/hermes-agent {
          inherit (llmPkgs) hermes-agent;
        };
        hermesSecret = description: ref: {
          inherit description ref;
          delivery = "envvar";
          owner = config.services.hermes-agent.user;
          group = config.services.hermes-agent.group;
          services = [ "hermes-agent" ];
        };
      in
      {
        imports = [ ../../../packages/hermes-agent/module.nix ];

        nixpkgs.config.permittedInsecurePackages = [
          # libolm is used by the Hermes Matrix client.
          "olm-3.2.16"
        ];

        services.secretspec = {
          enable = true;
          providers.op = {
            type = "onepassword";
            uri = "onepassword+token://Infrastructure";
            credentialFiles.OP_SERVICE_ACCOUNT_TOKEN = "/etc/opnix-token";
            packages = [ pkgs._1password-cli ];
            secrets = {
              MATRIX_ACCESS_TOKEN = hermesSecret "Matrix bot access token" {
                item = "matrix-bot";
                field = "hermes";
              };
              MATRIX_ALLOWED_USERS = hermesSecret "Matrix users allowed to message the bot" {
                item = "matrix-bot";
                field = "allowed-users";
              };
              MATRIX_RECOVERY_KEY = hermesSecret "Matrix recovery key" {
                item = "matrix-bot";
                field = "security-key";
              };
              OPENROUTER_API_KEY = hermesSecret "OpenRouter agent API key" {
                item = "openrouter-agent";
                field = "hermes";
              };
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
            MATRIX_ENCRYPTION = "true";
            MATRIX_HOMESERVER = "https://matrix.org";
          };
          environmentFiles = [ config.services.secretspec.scopeExportPath.hermes-agent ];
        };

        systemd.services.hermes-agent = {
          after = [ "secretspec-secrets.service" ];
          requires = [ "secretspec-secrets.service" ];
        };
      };
  };
}
