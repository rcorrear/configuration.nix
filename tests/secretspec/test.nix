{
  pkgs,
  self,
  secretspecPkg ? throw "tests/secretspec: `secretspecPkg` must be provided (the in-tree call site pins the flake's 0.19.1 build via packages/secretspec)",
  ...
}:
let
  inherit (pkgs) lib;

  secretspecModule = import "${self}/packages/secretspec/module.nix";

  evalAssertions =
    providers:
    (lib.evalModules {
      specialArgs = { inherit pkgs; };
      modules = [
        secretspecModule
        {
          options.assertions = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
          };
          config = {
            _module.check = false;
            services.secretspec = {
              enable = true;
              package = secretspecPkg;
              inherit providers;
            };
          };
        }
      ];
    }).config.assertions;

  envProvider = secrets: {
    test = {
      type = "env";
      uri = "env://";
      inherit secrets;
    };
  };

  secretNameAssertions =
    secrets:
    lib.filter (
      entry:
      lib.hasInfix "has an invalid name; " entry.message
      && (
        lib.hasPrefix "secretspec: secret `" entry.message
        || lib.hasPrefix "secretspec: envvar secret `" entry.message
      )
    ) (evalAssertions (envProvider secrets));

  interpolatedAssertions = evalAssertions (envProvider {
    source = {
      delivery = "envvar";
      ref.item = "SOURCE";
    };
    rendered = {
      delivery = "interpolated";
      template = "value={{source}}";
    };
  });

  invalidRefAssertions = evalAssertions (envProvider {
    envSecret = {
      delivery = "envvar";
      ref = {
        item = "ENV_SECRET";
        field = "invalid";
      };
    };
    fileSecret = {
      delivery = "file";
      ref = {
        item = "FILE_SECRET";
        version = "invalid";
      };
    };
  });

  invalidRefMessages = map (entry: entry.message) (
    lib.filter (entry: !entry.assertion) invalidRefAssertions
  );

  secret = delivery: {
    inherit delivery;
    ref.item = "TEST_VALUE";
  };

  acceptedNameAssertions = secretNameAssertions {
    _API_KEY2 = secret "envvar";
    file-key = secret "file";
    interpolated-key = {
      delivery = "interpolated";
      template = "value={{_API_KEY2}}";
    };
  };
  rejectedHyphenAssertions = secretNameAssertions {
    api-key = secret "envvar";
  };
  rejectedLeadingDigitAssertions = secretNameAssertions {
    "9key" = secret "envvar";
  };

  testSecrets = pkgs.writeTextDir "secrets.env" ''
    API_KEY=test-api-key-value
    DB_PASSWORD=test-db-password-value
    TLS_CERT=test-tls-cert-value
    SHELL_LITERAL='$(touch /tmp/secretspec-command-substitution) `touch /tmp/secretspec-backtick`'
  '';
in
assert lib.all (entry: entry.assertion) interpolatedAssertions;
assert builtins.elem
  "secretspec: secret `envSecret` under provider `test` (type `env`): `field` is not valid for this provider type"
  invalidRefMessages;
assert builtins.elem
  "secretspec: secret `fileSecret` under provider `test` (type `env`): `version` is not valid for this provider type"
  invalidRefMessages;
assert builtins.length acceptedNameAssertions == 4;
assert lib.all (entry: entry.assertion) acceptedNameAssertions;
assert builtins.length rejectedHyphenAssertions == 2;
assert builtins.length (lib.filter (entry: !entry.assertion) rejectedHyphenAssertions) == 1;
assert builtins.length rejectedLeadingDigitAssertions == 2;
assert builtins.length (lib.filter (entry: !entry.assertion) rejectedLeadingDigitAssertions) == 1;
{
  name = "secretspec";

  nodes.machine =
    { config, ... }:
    {
      imports = [ secretspecModule ];

      services.secretspec = {
        enable = true;
        package = secretspecPkg;
        project = "test-suite";

        providers.dotenv = {
          type = "dotenv";
          uri = "dotenv://${testSecrets}/secrets.env";
          secrets = {
            apiKey = {
              description = "API key for external service";
              delivery = "envvar";
              ref.item = "API_KEY";
              owner = "apiuser";
              group = "apiuser";
              services = [ "api-service" ];
            };
            dbPassword = {
              description = "Database password";
              delivery = "envvar";
              ref.item = "DB_PASSWORD";
              owner = "dbuser";
              group = "dbuser";
              services = [ "db-service" ];
            };
            shellLiteral = {
              description = "Value containing shell command syntax";
              delivery = "envvar";
              ref.item = "SHELL_LITERAL";
              owner = "dbuser";
              group = "dbuser";
              services = [ "db-service" ];
            };
            tlsCert = {
              description = "TLS certificate";
              delivery = "file";
              path = "/var/lib/secrets/tls-cert.pem";
              ref.item = "TLS_CERT";
              owner = "root";
              group = "root";
              mode = "0444";
              services = [
                "api-service"
                "db-service"
              ];
            };
            appConfig = {
              description = "Rendered app config with embedded secrets";
              delivery = "interpolated";
              template = ''
                api_key={{apiKey}}
                db_password={{dbPassword}}
                tls_cert={{tlsCert}}
                literal_dollar=$keep_me
              '';
              owner = "apiuser";
              group = "apiuser";
              mode = "0400";
              services = [ "api-service" ];
            };
          };
        };

        wrappedServices.api-service = {
          execStart = "${pkgs.writeShellScript "api-service" ''
            echo "apiKey=$apiKey"
            echo "tlsCert=$(cat /var/lib/secrets/tls-cert.pem)"
            echo "appConfig=$(cat /run/secrets/appConfig)"
            sleep infinity
          ''}";
        };
      };

      users = {
        groups.apiuser = { };
        groups.dbuser = { };
        users.apiuser = {
          isSystemUser = true;
          group = "apiuser";
        };
        users.dbuser = {
          isSystemUser = true;
          group = "dbuser";
        };
      };

      systemd.services.db-service = {
        description = "DB service that sources scope export and reads file secret";
        wantedBy = [ "multi-user.target" ];
        after = [ "secretspec-secrets.service" ];
        requires = [ "secretspec-secrets.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "dbuser";
          Group = "dbuser";
        };
        script = ''
          . ${config.services.secretspec.scopeExportPath.db-service}
          echo "dbPassword=$dbPassword"
          printf 'shellLiteral=%s\n' "$shellLiteral"
          echo "tlsCert=$(cat /var/lib/secrets/tls-cert.pem)"
        '';
      };
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("secretspec-secrets.service")

    # envvar delivery: not written as standalone file
    machine.fail("test -f /run/secrets/apiKey")
    machine.fail("test -f /run/secrets/dbPassword")

    # file delivery: written to custom path with correct content and ownership
    machine.fail("test -f /run/secrets/tlsCert")
    machine.succeed("test -f /var/lib/secrets/tls-cert.pem")
    machine.succeed("test \"$(cat /var/lib/secrets/tls-cert.pem)\" = \"test-tls-cert-value\"")
    machine.succeed("test \"$(stat -c %U /var/lib/secrets/tls-cert.pem)\" = \"root\"")
    machine.succeed("test \"$(stat -c %G /var/lib/secrets/tls-cert.pem)\" = \"root\"")
    machine.succeed("test \"$(stat -c %a /var/lib/secrets/tls-cert.pem)\" = \"444\"")

    # interpolated delivery: rendered file with all placeholders substituted
    machine.succeed("test -f /run/secrets/appConfig")
    machine.succeed("grep -q 'api_key=test-api-key-value' /run/secrets/appConfig")
    machine.succeed("grep -q 'db_password=test-db-password-value' /run/secrets/appConfig")
    machine.succeed("grep -q 'tls_cert=test-tls-cert-value' /run/secrets/appConfig")
    machine.succeed("grep -q 'literal_dollar=\\$keep_me' /run/secrets/appConfig")
    machine.succeed("test \"$(stat -c %U /run/secrets/appConfig)\" = \"apiuser\"")
    machine.succeed("test \"$(stat -c %a /run/secrets/appConfig)\" = \"400\"")

    # scope export files (envvar delivery only, owned by first secret's owner, mode 0400)
    machine.succeed("test -f /run/secrets/api-service.env")
    machine.succeed("test -f /run/secrets/db-service.env")
    machine.succeed("test \"$(stat -c %U /run/secrets/api-service.env)\" = \"apiuser\"")
    machine.succeed("test \"$(stat -c %U /run/secrets/db-service.env)\" = \"dbuser\"")
    machine.succeed("test \"$(stat -c %a /run/secrets/api-service.env)\" = \"400\"")
    machine.succeed("test \"$(stat -c %a /run/secrets/db-service.env)\" = \"400\"")
  ''
  + ''

    machine.wait_until_succeeds("journalctl -u db-service --no-pager -o cat | grep -q dbPassword")
    db_out = machine.succeed("journalctl -u db-service --no-pager -o cat")
    assert "dbPassword=test-db-password-value" in db_out, f"db-service did not receive dbPassword: {db_out}"
    assert "shellLiteral=$(touch /tmp/secretspec-command-substitution) `touch /tmp/secretspec-backtick`" in db_out, f"db-service did not preserve shell command syntax literally: {db_out}"
    assert "tlsCert=test-tls-cert-value" in db_out, f"db-service did not receive tlsCert: {db_out}"
    machine.fail("test -e /tmp/secretspec-command-substitution")
    machine.fail("test -e /tmp/secretspec-backtick")

    machine.wait_for_unit("api-service")
    api_out = machine.succeed("journalctl -u api-service --no-pager -o cat")
    assert "apiKey=test-api-key-value" in api_out, f"api-service did not receive apiKey: {api_out}"
    assert "tlsCert=test-tls-cert-value" in api_out, f"api-service did not receive tlsCert: {api_out}"
    assert "api_key=test-api-key-value" in api_out, f"api-service did not receive interpolated appConfig: {api_out}"
  '';
}
