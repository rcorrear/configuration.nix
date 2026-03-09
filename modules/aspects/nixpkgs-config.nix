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
      exiled-exchange2 = final.callPackage ../../packages/exiled-exchange2 { };
      zmx = final.callPackage ../../packages/zmx { };
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

  nixpkgsConfigUnfree = {
    allowUnfree = true;
  };
in
{
  flake-file.inputs = {
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.nixpkgs-config = {
    includes = [ ];

    nixos.nixpkgs = {
      config = nixpkgsConfigUnfree;
      overlays = overlaysFor (config._module.args.system or "");
    };

    homeManager.nixpkgs = {
      config = nixpkgsConfigUnfree;
      overlays = overlaysFor (config._module.args.system or "");
    };

    darwin.nixpkgs = {
      config = nixpkgsConfigUnfree;
      overlays = overlaysFor (config._module.args.system or "");
    };
  };
}
