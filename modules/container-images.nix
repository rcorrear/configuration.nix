{ lib, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      images = config.proxmoxImages;
      names = builtins.attrNames images;
      registry = pkgs.writeText "container-image-registry.json" (
        builtins.toJSON (
          lib.mapAttrs (name: _: {
            package = "${name}-image";
            check = "checks.${system}.image-${name}";
            contract = "legacyPackages.${system}.proxmoxImageContracts.${name}";
          }) images
        )
      );
      imageChecks = lib.mapAttrs (
        name: image:
        let
          contract = pkgs.writeText "${name}-image-contract.json" (builtins.toJSON image.contract);
          metadata = pkgs.runCommand "${name}-image-contract" { } ''
            ${pkgs.python3}/bin/python3 ${../packages/container-images/check-image.py} \
              descriptor ${image.image} ${contract}
            touch "$out"
          '';
          archive = pkgs.runCommand "${name}-oci-archive" { } ''
            ${lib.getExe image.image.copyTo} --tmpdir "$TMPDIR" \
              "oci-archive:$TMPDIR/image.tar:${name}"
            ${pkgs.python3}/bin/python3 ${../packages/container-images/check-image.py} \
              archive "$TMPDIR/image.tar" ${contract}
            touch "$out"
          '';
          tests = image.tests // {
            inherit metadata archive;
          };
        in
        {
          "image-${name}" = pkgs.linkFarm "${name}-image-checks" (
            lib.mapAttrsToList (testName: path: {
              name = testName;
              inherit path;
            }) tests
          );
        }
        // lib.mapAttrs' (testName: value: lib.nameValuePair "image-${name}-${testName}" value) tests
      ) images;
      commands = builtins.listToAttrs (
        map
          (
            action:
            lib.nameValuePair "${action}-image" (
              pkgs.writeShellApplication {
                name = "${action}-image";
                runtimeInputs = [ pkgs.nix ];
                text = ''
                  exec ${pkgs.python3}/bin/python3 ${../packages/container-images/cli.py} \
                    ${action} ${registry} ${../packages/container-images/check-image.py} "$@"
                '';
              }
            )
          )
          [
            "build"
            "check"
            "copy"
          ]
      );
    in
    {
      options.proxmoxImages = lib.mkOption {
        default = { };
        description = "Named nix2container images, runtime contracts, and application-specific checks.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              image = lib.mkOption { type = lib.types.package; };
              contract = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    user = lib.mkOption { type = lib.types.str; };
                    entrypoint = lib.mkOption { type = lib.types.listOf lib.types.str; };
                    ports = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                    };
                    volumes = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                    };
                    forbiddenEnvironment = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ "OP_SERVICE_ACCOUNT_TOKEN" ];
                    };
                    requiredMembers = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                    };
                    requireNixSymlinks = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                    };
                  };
                };
              };
              tests = lib.mkOption {
                type = lib.types.attrsOf lib.types.package;
                default = { };
                description = "Smoke tests and other app-specific checks included in the aggregate image check.";
              };
            };
          }
        );
      };
      config = lib.mkIf (names != [ ]) {
        legacyPackages.proxmoxImageContracts = lib.mapAttrs (_: image: image.contract) images;
        packages =
          lib.mapAttrs' (name: image: lib.nameValuePair "${name}-image" image.image) images // commands;
        checks = lib.foldl' (acc: checks: acc // checks) { } (builtins.attrValues imageChecks) // {
          container-image-tools = pkgs.runCommand "container-image-tools-tests" { } ''
            ${pkgs.python3}/bin/python3 ${../tests/container-images/test_tools.py} \
              ${../packages/container-images/cli.py} ${../packages/container-images/check-image.py}
            touch "$out"
          '';
        };
      };
    };
}
