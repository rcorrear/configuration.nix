{ den, ... }:
{
  den.aspects.renovate = {
    includes = [
      den.aspects.lxc-host
      den.aspects.opnix
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
          credentials = {
            RENOVATE_GITHUB_APP_PRIVATE_KEY =
              config.services.onepassword-secrets.secretPaths.renovateGithubAppPrivateKey;
            RENOVATE_GITHUB_CLIENT_ID = config.services.onepassword-secrets.secretPaths.renovateGithubClientId;
          };
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
            repositories = [ "rcorrear/omni" ];
          };
        };

        services.onepassword-secrets = {
          enable = true;
          secrets = {
            renovateGithubAppPrivateKey = {
              reference = "op://Infrastructure/renovate/github-app-private-key";
              services = [ "renovate" ];
            };
            renovateGithubClientId = {
              reference = "op://Infrastructure/renovate/github-client-id";
              services = [ "renovate" ];
            };
          };
        };

        systemd.services.renovate.script = lib.mkForce ''
          set -euo pipefail

          credentials_dir="$CREDENTIALS_DIRECTORY"
          private_key="$credentials_dir/SECRET-RENOVATE_GITHUB_APP_PRIVATE_KEY"
          client_id="$(cat "$credentials_dir/SECRET-RENOVATE_GITHUB_CLIENT_ID")"

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

        system.stateVersion = "25.11";
      };
  };
}
