{ inputs, lib, ... }:
{
  flake-file.inputs.nimi = {
    url = "github:weyl-ai/nimi/99312337b455329adc94105a4a1f371edf6d6aa0";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      nimiPkgs = pkgs.extend inputs.nimi.overlays.default;
      imageTools = import ../packages/9router/nix2container.nix {
        inherit pkgs;
        source = inputs.nimi.inputs.nix2container;
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
      image = import ../packages/9router/image.nix {
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
      gatewayTest = import ../tests/9router/gateway-eval.nix {
        inherit pkgs;
        inherit (inputs.nixpkgs.lib) nixosSystem;
        gatewayModule = ../packages/tailscale-service-gateway/module.nix;
      };
      gatewayLifecycleTest = import ../tests/9router/gateway-lifecycle.nix {
        inherit pkgs;
        gatewayModule = ../packages/tailscale-service-gateway/module.nix;
      };
      commonContract = {
        ports = [ "20128/tcp" ];
        volumes = [ "/var/lib/9router" ];
        forbiddenEnvironment = [
          "INITIAL_PASSWORD"
          "JWT_SECRET"
          "API_KEY_SECRET"
          "MACHINE_ID_SALT"
          "OP_SERVICE_ACCOUNT_TOKEN"
        ];
        requiredMembers = [
          "etc/passwd"
          "etc/group"
        ];
      };
    in
    {
      proxmoxImages = lib.optionalAttrs (system == "x86_64-linux") {
        "9router" = {
          inherit (image) image;
          contract = commonContract // {
            user = "0:0";
            entrypoint = [ (lib.getExe image.runner) ];
          };
          tests = {
            smoke = privilegeTest;
            gateway = gatewayTest;
            gateway-lifecycle = gatewayLifecycleTest;
          };
        };
      };
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        "9router-nimi" = image.runner;
        # Compatibility entrypoints; normal validation uses flake checks.
        "9router-smoke" = privilegeTest.driver;
      };
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        # Retain existing check names for callers of the original interface.
        "9router-secretspec" = privilegeTest;
        "9router-gateway" = gatewayTest;
        "9router-gateway-lifecycle" = gatewayLifecycleTest;
        "9router-image-contract" = config.checks.image-9router-metadata;
        "9router-oci-archive" = config.checks.image-9router-archive;
      };
    };
}
