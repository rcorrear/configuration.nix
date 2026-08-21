{ den, ... }:
{
  den.aspects.renovate = {
    includes = [
      den.aspects.lxc-host
      den.aspects.secretspec
    ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        networking = {
          interfaces.net1.useDHCP = true;
          search = [
            "home.arpa"
          ];
        };

        services.renovate = {
          enable = true;
          runtimePackages = [ pkgs.nix ];
          # environment.LOG_LEVEL = "debug";
          schedule = "*-*-* *:00/30:00";
          settings = {
            allowedCommands = [ "^nix run \\.#locker$" ];
            labels = [ "renovate" ];
            platform = "github";
            platformCommit = "enabled";
            persistRepoData = true;
            packageRules = [
              {
                groupName = "Ring";
                groupSlug = "ring";
                matchManagers = [ "clojure" ];
                matchPackageNames = [
                  "ring:ring-core"
                  "ring:ring-jetty-adapter"
                ];
              }
              {
                groupName = "polylith-kaocha";
                groupSlug = "polylith-kaocha";
                matchManagers = [ "clojure" ];
                matchPackageNames = [ "imrekoszo/polylith-kaocha" ];
              }
              {
                matchDatasources = [ "clojure" ];
                matchPackageNames = [ "com.rpl:agent-o-rama" ];
                registryUrls = [ "https://nexus.redplanetlabs.com/repository/maven-public-releases/" ];
              }
            ];
            repositories = [
              "rcorrear/omni"
              "rcorrear/configuration.nix"
            ];
          };
        };

        services.secretspec = {
          enable = true;
          providers.op = {
            type = "onepassword";
            uri = "onepassword+token://Infrastructure";
            credentialFiles.OP_SERVICE_ACCOUNT_TOKEN = "/etc/opnix-token";
            packages = [ pkgs._1password-cli ];
            secrets = {
              renovateGithubAppPrivateKey = {
                description = "Renovate GitHub App private key";
                delivery = "file";
                ref = {
                  item = "renovate";
                  field = "github-app-private-key";
                };
                services = [ "renovate" ];
              };
              RENOVATE_GITHUB_CLIENT_ID = {
                description = "Renovate GitHub client ID";
                delivery = "envvar";
                ref = {
                  item = "renovate";
                  field = "github-client-id";
                };
                services = [ "renovate" ];
              };
            };
          };
        };

        systemd.services.renovate = {
          after = [ "secretspec-secrets.service" ];
          requires = [ "secretspec-secrets.service" ];
          script = lib.mkForce ''
            set -euo pipefail
            . ${config.services.secretspec.scopeExportPath.renovate}

            private_key="${config.services.secretspec.secretPaths.renovateGithubAppPrivateKey}"
            client_id="$RENOVATE_GITHUB_CLIENT_ID"

            base64url() {
              ${pkgs.coreutils}/bin/base64 --wrap=0 | ${pkgs.coreutils}/bin/tr '+/' '-_' | ${pkgs.coreutils}/bin/tr -d '='
            }

            now="$(${pkgs.coreutils}/bin/date +%s)"
            header="$(printf '%s' '{"alg":"RS256","typ":"JWT"}' | base64url)"
            payload="$(${pkgs.jq}/bin/jq --compact-output --null-input \
              --argjson issued_at "$((now - 60))" \
              --argjson expires_at "$((now + 540))" \
              --arg client_id "$client_id" \
              '{ iat: $issued_at, exp: $expires_at, iss: $client_id }' | base64url)"
            signature="$(printf '%s' "$header.$payload" | ${pkgs.openssl}/bin/openssl dgst -binary -sha256 -sign "$private_key" | base64url)"
            jwt="$header.$payload.$signature"

            installation_id="$(${pkgs.curl}/bin/curl --fail --silent --show-error \
              --header "Accept: application/vnd.github+json" \
              --header "Authorization: Bearer $jwt" \
              --header "X-GitHub-Api-Version: 2022-11-28" \
              "https://api.github.com/users/rcorrear/installation" \
              | ${pkgs.jq}/bin/jq --exit-status --raw-output '.id')"

            export RENOVATE_TOKEN="$(${pkgs.curl}/bin/curl --fail --silent --show-error \
              --request POST \
              --header "Accept: application/vnd.github+json" \
              --header "Authorization: Bearer $jwt" \
              --header "X-GitHub-Api-Version: 2022-11-28" \
              "https://api.github.com/app/installations/$installation_id/access_tokens" \
              | ${pkgs.jq}/bin/jq --exit-status --raw-output '.token')"

            exec ${lib.getExe config.services.renovate.package}
          '';
        };

        system.stateVersion = "25.11";
      };
  };
}
