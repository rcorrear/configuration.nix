# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    delta.url = "github:zed-industries/delta-nix";
    den.url = "github:denful/den";
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:denful/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    graphify.url = "github:rcorrear/graphify";
    herdr.url = "github:ogulcancelik/herdr";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    lanzaboote.url = "github:nix-community/lanzaboote";
    llm-agents.url = "github:numtide/llm-agents.nix";
    microvm = {
      url = "github:microvm-nix/microvm.nix/136cbec280d47152c511f8d8f0c5ca18cde54f7f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nimi = {
      url = "github:rcorrear/nimi/99312337b455329adc94105a4a1f371edf6d6aa0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    opnix.url = "github:brizzbuzz/opnix";
    secretspec = {
      url = "github:cachix/secretspec";
      flake = false;
    };
    stylix.url = "github:danth/stylix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
}
