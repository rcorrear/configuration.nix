{ inputs, lib, ... }:
{
  flake-file.inputs.nimi = {
    url = "github:weyl-ai/nimi/99312337b455329adc94105a4a1f371edf6d6aa0";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    { pkgs, system, ... }:
    let
      nimiPkgs = pkgs.extend inputs.nimi.overlays.default;
      imageTools = import ../packages/9router/nix2container.nix {
        inherit pkgs;
        source = inputs.nimi.inputs.nix2container;
      };
      fileImage = import ../packages/9router/image.nix {
        inherit pkgs;
        inherit (nimiPkgs) nimi;
        inherit (imageTools) nix2container;
      };
      opPkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = p: lib.getName p == "1password-cli";
      };
      secretspec = pkgs.callPackage ../packages/secretspec { inherit (inputs) secretspec; };
      secretRuntime = import ../packages/9router/secretspec.nix {
        inherit pkgs secretspec;
        onepasswordCli = opPkgs._1password-cli;
      };
      secretspecImage = import ../packages/9router/image.nix {
        inherit pkgs secretRuntime;
        inherit (nimiPkgs) nimi;
        inherit (imageTools) nix2container;
      };
      secretTests = import ../tests/9router/secretspec.nix {
        inherit pkgs secretspec;
      };
      testImage = import ../packages/9router/image.nix {
        inherit pkgs;
        inherit (nimiPkgs) nimi;
        inherit (imageTools) nix2container;
        secretRuntime = import ../packages/9router/secretspec.nix {
          inherit pkgs secretspec;
          onepasswordCli = secretTests.mockOp;
        };
      };
      privilegeTest = import ../tests/9router/privileges.nix {
        inherit pkgs secretTests;
        inherit (testImage) runner;
      };
    in
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        "9router-image" = fileImage.image;
        "9router-nimi" = fileImage.runner;
        "9router-secretspec-image" = secretspecImage.image;
        "9router-secretspec-nimi" = secretspecImage.runner;
        # A VM supplies real root and UID 1000 without host privileges.
        "9router-secretspec-smoke" = privilegeTest.driver;
        "9router-smoke" = pkgs.writeShellApplication {
          name = "9router-smoke";
          runtimeInputs = [
            pkgs.bubblewrap
            pkgs.curl
            pkgs.coreutils
            pkgs.bash
          ];
          text = ''
            export NINE_ROUTER_RUNNER=${lib.getExe fileImage.runner}
            ${builtins.readFile ../tests/9router/smoke.sh}
          '';
        };
      };
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        "9router-secretspec" = privilegeTest;
        "9router-secretspec-oci-archive" =
          pkgs.runCommand "9router-secretspec-oci-archive" { nativeBuildInputs = [ pkgs.python3 ]; }
            ''
              ${lib.getExe secretspecImage.image.copyTo} --tmpdir "$TMPDIR" \
                "oci-archive:$TMPDIR/9router.oci.tar:9router-secretspec"
              python3 ${../tests/9router/check-oci-archive.py} "$TMPDIR/9router.oci.tar" 0:0
              touch "$out"
            '';
        "9router-gateway" = import ../tests/9router/gateway-eval.nix {
          inherit pkgs;
          inherit (inputs.nixpkgs.lib) nixosSystem;
          gatewayModule = ../packages/tailscale-service-gateway/module.nix;
        };
        "9router-image-contract" =
          pkgs.runCommand "9router-image-contract"
            {
              nativeBuildInputs = [ pkgs.python3 ];
            }
            ''
              python3 - ${fileImage.image} <<'PY'
              import json, sys
              image = json.load(open(sys.argv[1]))
              cfg = image["image-config"]
              assert cfg["User"] == "1000:1000"
              assert cfg["Entrypoint"][0].endswith("/bin/9router-nimi")
              assert "/var/lib/9router" in cfg["Volumes"]
              assert "20128/tcp" in cfg["ExposedPorts"]
              assert not any("SECRET=" in e or "PASSWORD=" in e for e in cfg["Env"])
              PY
              touch "$out"
            '';
        "9router-oci-archive" =
          pkgs.runCommand "9router-oci-archive"
            {
              nativeBuildInputs = [ pkgs.python3 ];
            }
            ''
              ${lib.getExe fileImage.image.copyTo} --tmpdir "$TMPDIR" \
                "oci-archive:$TMPDIR/9router.oci.tar:9router"
              python3 ${../tests/9router/check-oci-archive.py} "$TMPDIR/9router.oci.tar"
              touch "$out"
            '';
      };
    };
}
