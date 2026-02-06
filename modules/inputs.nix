# This repo was generated with github:vic/flake-file#dendritic template.
# Run `nix run .#write-flake` after changing any input.
#
# Inputs can be placed in any module, the best practice is to have them
# as close as possible to their actual usage.
# See: https://vic.github.io/dendrix/Dendritic.html#minimal-and-focused-flakenix
#
# For our template, we enable home-manager and nix-darwin by default, but
# you are free to remove them if not being used by you.
_: {
  flake-file.inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # zmx = {
    #   url = "github:neurosnap/zmx/v0.3.0";
    #   inputs.zig2nix.inputs.nixpkgs.follows = "nixpkgs";
    # };

    ## these stable inputs are for wsl
    #nixpkgs-stable.url = "github:nixos/nixpkgs/release-25.05";
    #home-manager-stable.url = "github:nix-community/home-manager/release-25.05";
    #home-manager-stable.inputs.nixpkgs.follows = "nixpkgs-stable";

    #nixos-wsl = {
    #  url = "github:nix-community/nixos-wsl";
    #  inputs.nixpkgs.follows = "nixpkgs-stable";
    #  inputs.flake-compat.follows = "";
    #};

  };

}
