{
  inputs,
  lib,
  config,
  ...
}:
let
  rcorrearOverlay = final: prev: {
    rcorrear = {
      cider-3 = final.callPackage ../../packages/cider-3 { };
      exiled-exchange2 = final.callPackage ../../packages/exiled-exchange2 { };
      headroom = final.callPackage ../../packages/headroom { };
      rtk = final.callPackage ../../packages/rtk { };
      zmx = final.callPackage ../../packages/zmx { };
    };

    # Work around an upstream OpenLDAP 2.6.13 syncrepl test failure that
    # currently blocks Lutris through its transitive dependency chain.
    openldap = prev.openldap.overrideAttrs (_: {
      doCheck = false;
    });
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
    permittedInsecurePackages = [
      "olm-3.2.16"
    ];
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
