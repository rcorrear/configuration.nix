{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.secretspec;

  allSecrets = lib.foldlAttrs (
    acc: alias: p:
    acc // (lib.mapAttrs (_name: s: s // { providers = [ alias ]; }) p.secrets)
  ) { } cfg.providers;

  allSecretNames = lib.flatten (
    lib.mapAttrsToList (_alias: p: builtins.attrNames p.secrets) cfg.providers
  );

  tomlSecrets = lib.filterAttrs (_: s: s.delivery != "interpolated") allSecrets;

  envvarSecrets = lib.filterAttrs (_: s: s.delivery == "envvar") allSecrets;
  fileSecrets = lib.filterAttrs (_: s: s.delivery == "file") allSecrets;
  interpolatedSecrets = lib.filterAttrs (_: s: s.delivery == "interpolated") allSecrets;

  hasInterpolated = builtins.length (builtins.attrNames interpolatedSecrets) > 0;

  secretPath = name: secret: if secret.path != "" then secret.path else "/run/secrets/${name}";

  providerPackages = lib.flatten (lib.mapAttrsToList (_alias: p: p.packages) cfg.providers);

  generatedScopes = lib.foldlAttrs (
    acc: secretName: secret:
    lib.foldl (
      acc: svc:
      let
        existing = acc.${svc} or { secrets = [ ]; };
      in
      acc
      // {
        ${svc} = {
          secrets = existing.secrets ++ [ secretName ];
        };
      }
    ) acc secret.services
  ) { } envvarSecrets;

  extractRefs =
    template:
    let
      parts = builtins.split "[{][{]([a-zA-Z_][a-zA-Z0-9_-]*)[}][}]" template;
      captures = lib.filter builtins.isList parts;
    in
    lib.unique (map (x: builtins.elemAt x 0) captures);

  interpolatedData = lib.mapAttrs (
    name: s:
    let
      refs = extractRefs s.template;
      indexed = lib.imap0 (i: r: {
        ref = r;
        envVar = "SECRETSPEC_REF_${toString i}";
      }) refs;
      templateEnv = lib.replaceStrings (map (x: "{{${x.ref}}}") indexed) (map (
        x: "\${${x.envVar}}"
      ) indexed) s.template;
    in
    {
      templateFile = pkgs.writeText "secretspec-template-${name}" templateEnv;
      inherit refs;
      shellFormat = lib.concatStringsSep " " (map (x: "\${${x.envVar}}") indexed);
    }
  ) interpolatedSecrets;

  tomlString = builtins.toJSON;

  tomlArray = items: "[" + lib.concatStringsSep ", " (map tomlString items) + "]";

  secretspecToml = pkgs.writeText "secretspec.toml" ''
    [project]
    name = ${tomlString cfg.project}
    revision = "1.0"

    [providers]
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (alias: p: "${alias} = ${tomlString p.uri}") cfg.providers
    )}

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: secret: ''
        [profiles.default.${name}]
        description = ${tomlString secret.description}
        providers = ${tomlArray secret.providers}
        ${lib.optionalString secret.asPath "as_path = true"}

        [profiles.default.${name}.ref]
        ${lib.optionalString (secret.ref.section != "") "section = ${tomlString secret.ref.section}"}
        item = ${tomlString secret.ref.item}
        ${lib.optionalString (secret.ref.field != "") "field = ${tomlString secret.ref.field}"}
        ${lib.optionalString (secret.ref.version != "") "version = ${tomlString secret.ref.version}"}
      '') tomlSecrets
    )}

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (scope: s: ''
        [scopes.${scope}]
        secrets = ${tomlArray s.secrets}
      '') generatedScopes
    )}
  '';

  scopeOwner =
    scope:
    let
      secretNames = (generatedScopes.${scope} or { secrets = [ ]; }).secrets;
      firstSecretName = builtins.head secretNames;
      firstSecret = allSecrets.${firstSecretName};
    in
    {
      inherit (firstSecret) owner group;
    };

  credentialLines = lib.flatten (
    lib.mapAttrsToList (
      _alias: p:
      lib.mapAttrsToList (
        envVar: filePath: "export ${envVar}=\"$(cat ${lib.escapeShellArg filePath})\""
      ) p.credentialFiles
    ) cfg.providers
  );

  providerAssertions =
    let
      perSecretAssertions =
        alias: p: name: s:
        if p.type == "env" || p.type == "dotenv" then
          lib.optional (s.ref.field != "") {
            assertion = false;
            message = "secretspec: secret `${name}` under provider `${alias}` (type `${p.type}`): `field` is not valid for this provider type";
          }
          ++ lib.optional (s.ref.section != "") {
            assertion = false;
            message = "secretspec: secret `${name}` under provider `${alias}` (type `${p.type}`): `section` is not valid for this provider type";
          }
          ++ lib.optional (s.ref.version != "") {
            assertion = false;
            message = "secretspec: secret `${name}` under provider `${alias}` (type `${p.type}`): `version` is not valid for this provider type";
          }
        else if p.type == "vault" then
          lib.optional (s.ref.field == "") {
            assertion = false;
            message = "secretspec: secret `${name}` under provider `${alias}` (type `vault`): `field` is required for vault provider";
          }
          ++ lib.optional (s.ref.section != "") {
            assertion = false;
            message = "secretspec: secret `${name}` under provider `${alias}` (type `vault`): `section` is not valid for vault provider";
          }
          ++ lib.optional (s.ref.version != "") {
            assertion = false;
            message = "secretspec: secret `${name}` under provider `${alias}` (type `vault`): `version` is not valid for vault provider";
          }
        else if p.type == "onepassword" then
          lib.optional (s.ref.section != "" && s.ref.field == "") {
            assertion = false;
            message = "secretspec: secret `${name}` under provider `${alias}` (type `onepassword`): `section` requires `field` to be set";
          }
        else
          [ ];
    in
    lib.flatten (
      lib.mapAttrsToList (
        alias: p: lib.flatten (lib.mapAttrsToList (perSecretAssertions alias p) p.secrets)
      ) cfg.providers
    );

  deliveryAssertions = lib.flatten (
    lib.mapAttrsToList (
      name: s:
      (
        if s.delivery == "interpolated" then
          [
            {
              assertion = s.template != "";
              message = "secretspec: secret `${name}` has delivery='interpolated' but template is empty";
            }
          ]
          ++ (map (ref: {
            assertion = tomlSecrets ? ${ref};
            message = "secretspec: secret `${name}` template references `${ref}` which is not a declared secret (or is itself interpolated)";
          }) interpolatedData.${name}.refs)
          ++ (lib.flatten (
            map (
              ref:
              lib.optional (tomlSecrets ? ${ref}) {
                assertion = !(tomlSecrets.${ref}.asPath or false);
                message = "secretspec: secret `${name}` template references `${ref}`, which has `asPath = true`; asPath secrets resolve to a file path rather than a value and cannot be interpolated into templates";
              }
            ) interpolatedData.${name}.refs
          ))
        else
          [
            {
              assertion = s.template == "";
              message = "secretspec: secret `${name}` has delivery='${s.delivery}' but template is set (template is only for delivery='interpolated')";
            }
          ]
          ++ lib.optional (s.delivery == "envvar") {
            assertion = s.path == "";
            message = "secretspec: secret `${name}` has delivery='envvar' but path is set (path is only for delivery='file' or 'interpolated')";
          }
          ++ lib.optional (s.delivery == "envvar" && s.mode != "0400") {
            assertion = false;
            message = "secretspec: secret `${name}` has delivery='envvar' but mode is set (mode is only for delivery='file' or 'interpolated')";
          }
      )
    ) allSecrets
  );

  scopeAssertions = lib.flatten (
    lib.mapAttrsToList (
      scope: s:
      let
        owners = lib.unique (map (n: allSecrets.${n}.owner) s.secrets);
        groups = lib.unique (map (n: allSecrets.${n}.group) s.secrets);
      in
      lib.optional (builtins.length owners > 1) {
        assertion = false;
        message = "secretspec: scope `${scope}` combines envvar secrets with differing owners (${lib.concatStringsSep ", " owners}); scope export ownership is ambiguous";
      }
      ++ lib.optional (builtins.length groups > 1) {
        assertion = false;
        message = "secretspec: scope `${scope}` combines envvar secrets with differing groups (${lib.concatStringsSep ", " groups}); scope export ownership is ambiguous";
      }
    ) generatedScopes
  );

  wrappedServiceAssertions = lib.mapAttrsToList (name: _opts: {
    assertion = generatedScopes ? ${name};
    message = "secretspec: wrappedService `${name}` has no corresponding scope; add an envvar secret with `services = [ \"${name}\" ]` so a scope is generated for `secretspec run --scope ${name}`";
  }) cfg.wrappedServices;

  serviceNameAssertions = lib.flatten (
    lib.mapAttrsToList (
      name: s:
      map (svc: {
        assertion = svc != "" && !lib.hasInfix "/" svc;
        message = "secretspec: secret `${name}` references service `${svc}` with an invalid name; service names must be non-empty and must not contain `/` (used to build /run/secrets/<scope>.env paths and scope arguments)";
      }) s.services
    ) allSecrets
  );
in
{
  options.services.secretspec = {
    enable = lib.mkEnableOption "SecretSpec secret management";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.secretspec;
      description = "The SecretSpec package to use.";
    };

    project = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "SecretSpec project name (metadata only; does not affect ref-based resolution).";
    };

    providers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.str;
              description = ''
                Provider type, determines which ref fields its secrets accept:
                - `onepassword`: `item` (required), `field`, `section`, `version` (optional)
                - `dotenv`/`env`: `item` (required)
                - `vault`: `item` (required), `field` (required)
              '';
            };
            uri = lib.mkOption {
              type = lib.types.str;
              description = "SecretSpec provider URI, e.g. `onepassword+token://Infrastructure` or `dotenv:///path/to/secrets.env`.";
            };
            credentialFiles = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Map of environment variable name to file path. Each file is read at runtime and exported as the named env var for SecretSpec provider authentication, e.g. `{ OP_SERVICE_ACCOUNT_TOKEN = \"/etc/opnix-token\"; }`.";
            };
            packages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = "Runtime packages the provider needs, e.g. `pkgs._1password-cli` for the 1Password provider. Added to system packages and service PATH.";
            };
            secrets = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    description = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                      description = "Human-readable description of the secret.";
                    };
                    delivery = lib.mkOption {
                      type = lib.types.enum [
                        "envvar"
                        "file"
                        "interpolated"
                      ];
                      description = ''
                        How the secret is delivered to consuming services:
                        - `envvar`: appears in scope export files (`NAME=value`). Not written as a standalone file.
                        - `file`: written as a standalone file at `path` (default `/run/secrets/NAME`). Not included in scope exports.
                        - `interpolated`: rendered from `template` with `{{SECRET_NAME}}` placeholders substituted at runtime. Written as a file at `path` (default `/run/secrets/NAME`).
                      '';
                    };
                    path = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                      description = "Custom file path for `file` and `interpolated` delivery. Empty defaults to `/run/secrets/NAME`. Ignored for `envvar` delivery.";
                    };
                    template = lib.mkOption {
                      type = lib.types.lines;
                      default = "";
                      description = "Template content with `{{SECRET_NAME}}` placeholders. Only for `delivery='interpolated'`. Referenced secrets must be declared with `delivery='envvar'` or `delivery='file'`.";
                    };
                    ref = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          section = lib.mkOption {
                            type = lib.types.str;
                            default = "";
                            description = "Named group of fields inside the item (1Password only). Requires `field`.";
                          };
                          item = lib.mkOption {
                            type = lib.types.str;
                            description = "The store's complete name for the secret.";
                          };
                          field = lib.mkOption {
                            type = lib.types.str;
                            default = "";
                            description = "A named component inside the item. Empty reads the item value field.";
                          };
                          version = lib.mkOption {
                            type = lib.types.str;
                            default = "";
                            description = "Which revision to read (supported by versioned stores). Empty reads the latest.";
                          };
                        };
                      };
                      description = "Native SecretSpec reference coordinates naming an externally managed secret. Not used when `delivery='interpolated'`.";
                    };
                    owner = lib.mkOption {
                      type = lib.types.str;
                      default = "root";
                      description = "Owner of the secret file (`file`/`interpolated` delivery) or scope export file (`envvar` delivery).";
                    };
                    group = lib.mkOption {
                      type = lib.types.str;
                      default = "root";
                      description = "Group of the secret file (`file`/`interpolated` delivery) or scope export file (`envvar` delivery).";
                    };
                    mode = lib.mkOption {
                      type = lib.types.str;
                      default = "0400";
                      description = "File mode of the secret file. Only for `file` and `interpolated` delivery.";
                    };
                    asPath = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "When true, SecretSpec materializes the secret as a temp file and returns the file path instead of the value. Only for `file` delivery.";
                    };
                    services = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = "systemd services that consume this secret. For `envvar` delivery, used to generate SecretSpec scopes. For all delivery modes, used for documentation of service dependencies.";
                    };
                  };
                }
              );
              default = { };
              description = "Secret declarations resolved via SecretSpec for this provider.";
            };
          };
        }
      );
      default = { };
      description = "SecretSpec providers. Each provider has a type, URI, optional credential files, and its own set of secrets.";
    };

    secretPaths = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      description = "Map of secret name to file path. Only includes `file` and `interpolated` delivery secrets.";
    };

    manifest = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      description = "Path to the generated secretspec.toml manifest.";
    };

    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      description = "Environment variables for SecretSpec resolution. Set on the secretspec-secrets service unit.";
    };

    setupScript = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Shell snippet that sets up the SecretSpec environment including provider credentials. Used by the secretspec-secrets service.";
    };

    scopeExportPath = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      description = "Map of scope name to generated env file path (`envvar` delivery only). Source these in consuming service scripts or pass to `environmentFiles`.";
    };

    wrappedServices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            execStart = lib.mkOption {
              type = lib.types.str;
              description = "Original ExecStart command to wrap with `secretspec run`.";
            };
          };
        }
      );
      default = { };
      description = "Services to wrap with `secretspec run` (envvar injection via process environment).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      providerAssertions
      ++ deliveryAssertions
      ++ scopeAssertions
      ++ wrappedServiceAssertions
      ++ serviceNameAssertions
      ++ [
        {
          assertion = builtins.length allSecretNames == builtins.length (lib.unique allSecretNames);
          message = "secretspec: secret names must be unique across all providers";
        }
      ];

    services.secretspec = {
      secretPaths = lib.mapAttrs secretPath (fileSecrets // interpolatedSecrets);
      manifest = secretspecToml;
      env = {
        SECRETSPEC_FILE = "${secretspecToml}";
        SECRETSPEC_PROFILE = "default";
      };
      setupScript = ''
        export PATH="${
          lib.makeBinPath ([ cfg.package ] ++ providerPackages ++ lib.optional hasInterpolated pkgs.gettext)
        }:$PATH"
        export SECRETSPEC_FILE="${secretspecToml}"
        export SECRETSPEC_PROFILE="default"
        ${lib.concatStringsSep "\n" credentialLines}
      '';
      scopeExportPath = lib.mapAttrs (scope: _: "/run/secrets/${scope}.env") generatedScopes;
    };

    environment.systemPackages = [ cfg.package ] ++ providerPackages;

    systemd.services = lib.mkMerge [
      {
        secretspec-secrets = {
          description = "Resolve secrets via SecretSpec";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          environment = cfg.env // {
            HOME = "/root";
          };
          path = [ cfg.package ] ++ providerPackages ++ lib.optional hasInterpolated pkgs.gettext;
          script = ''
            set -euo pipefail
            ${lib.concatStringsSep "\n" credentialLines}

            ${cfg.package}/bin/secretspec check --no-prompt

            mkdir -p /run/secrets
            chmod 0711 /run/secrets

            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: secret:
                let
                  outPath = secretPath name secret;
                in
                ''
                  mkdir -p "$(dirname ${lib.escapeShellArg outPath})"
                  ( umask 0077 ; ${cfg.package}/bin/secretspec get ${lib.escapeShellArg name} > ${lib.escapeShellArg outPath} )
                  chown ${lib.escapeShellArg secret.owner}:${lib.escapeShellArg secret.group} ${lib.escapeShellArg outPath}
                  chmod ${lib.escapeShellArg secret.mode} ${lib.escapeShellArg outPath}
                ''
              ) fileSecrets
            )}

            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: secret:
                let
                  data = interpolatedData.${name};
                  outPath = secretPath name secret;
                in
                ''
                  ${lib.concatStringsSep "\n" (
                    lib.imap0 (i: ref: ''
                      SECRETSPEC_REF_${toString i}="$(${cfg.package}/bin/secretspec get ${lib.escapeShellArg ref})"
                      export SECRETSPEC_REF_${toString i}
                    '') data.refs
                  )}
                  mkdir -p "$(dirname ${lib.escapeShellArg outPath})"
                  ( umask 0077 ; ${pkgs.gettext}/bin/envsubst '${data.shellFormat}' < ${data.templateFile} > ${lib.escapeShellArg outPath} )
                  chown ${lib.escapeShellArg secret.owner}:${lib.escapeShellArg secret.group} ${lib.escapeShellArg outPath}
                  chmod ${lib.escapeShellArg secret.mode} ${lib.escapeShellArg outPath}
                ''
              ) interpolatedSecrets
            )}

            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                scope: _s:
                let
                  inherit (scopeOwner scope) owner group;
                in
                ''
                  ( umask 0077 ; ${cfg.package}/bin/secretspec export --scope ${lib.escapeShellArg scope} --format shell | ${pkgs.gnused}/bin/sed 's/^export //' > /run/secrets/${lib.escapeShellArg scope}.env )
                  chown ${lib.escapeShellArg owner}:${lib.escapeShellArg group} /run/secrets/${lib.escapeShellArg scope}.env
                  chmod 0400 /run/secrets/${lib.escapeShellArg scope}.env
                ''
              ) generatedScopes
            )}
          '';
        };
      }
      (lib.mapAttrs' (name: opts: {
        inherit name;
        value =
          let
            wrapper = pkgs.writeShellScript "secretspec-run-${name}" ''
              export PATH="${lib.makeBinPath ([ cfg.package ] ++ providerPackages)}:$PATH"
              export SECRETSPEC_FILE="${secretspecToml}"
              export SECRETSPEC_PROFILE="default"
              ${lib.concatStringsSep "\n" credentialLines}
              exec ${cfg.package}/bin/secretspec run --scope ${lib.escapeShellArg name} -- ${opts.execStart}
            '';
          in
          {
            wantedBy = [ "multi-user.target" ];
            after = [ "secretspec-secrets.service" ];
            requires = [ "secretspec-secrets.service" ];
            serviceConfig.ExecStart = lib.mkForce "${wrapper}";
          };
      }) cfg.wrappedServices)
    ];
  };
}
