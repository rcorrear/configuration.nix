{
  inputs,
  lib,
  config,
  ...
}:
let
  rcorrearOverlay = final: _prev: {
    rcorrear = {
      cider-3 = final.callPackage ../../packages/cider-3 { };
      codex-acp = final.callPackage ../../packages/codex-acp { };
      exiled-exchange2 = final.callPackage ../../packages/exiled-exchange2 { };
    };
  };

  overlaysFor =
    system:
    [
      rcorrearOverlay
      inputs.opnix.overlays.default
    ]
    ++ lib.optionals (lib.hasInfix "linux" system) [
      inputs.niri-flake.overlays.niri
    ];

  nixpkgsConfigWithInsecureDotnet = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "dotnet-runtime-6.0.36"
      "dotnet-sdk-6.0.136"
      "dotnet-sdk-6.0.428"
    ];
  };
in
{
  flake-file.inputs.opnix = {
    url = "github:brizzbuzz/opnix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.inputs.niri-flake = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.nixpkgs-config = {
    includes = [ ];

    nixos.nixpkgs = {
      config = nixpkgsConfigWithInsecureDotnet;
      overlays = overlaysFor (config._module.args.system or "");
    };

    homeManager.nixpkgs = {
      config = nixpkgsConfigWithInsecureDotnet;
      overlays = overlaysFor (config._module.args.system or "");
    };

    darwin.nixpkgs = {
      config = nixpkgsConfigWithInsecureDotnet;
      overlays = overlaysFor (config._module.args.system or "");
    };
  };
}
