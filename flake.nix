{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
    };

    opnix = {
      url = "github:mrjones2014/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    # The name "snowfall-lib" is required due to how Snowfall Lib processes flake inputs.
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
    };
  };

  # We will handle this in the next section.
  outputs =
    inputs:
    inputs.snowfall-lib.mkFlake {
      # You must provide our flake inputs to Snowfall Lib.
      inherit inputs;

      channels-config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "dotnet-runtime-6.0.36"
          "dotnet-sdk-6.0.136"
          "dotnet-sdk-6.0.428"
        ];
      };

      nixos.modules = [
        inputs.devenv.flakeModule
      ];

      snowfall.namespace = "rcorrear";

      # The `src` must be the root of the flake. See configuration
      # in the next section for information on how you can move your
      # Nix files to a separate directory.
      src = builtins.path {
        path = ./.;
        name = "source";
      };

      # The outputs builder receives an attribute set of your available NixPkgs channels.
      # These are every input that points to a NixPkgs instance (even forks). In this
      # case, the only channel available in this flake is `channels.nixpkgs`.
      outputs-builder = channels: {
        # Outputs in the outputs builder are transformed to support each system. This
        # entry will be turned into multiple different outputs like `formatter.x86_64-linux.*`.
        formatter = channels.nixpkgs.nixfmt-rfc-style;
      };
    };
}
