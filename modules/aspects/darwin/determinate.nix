{
  # Provides `inputs.determinate.darwinModules.default`: the officially
  # supported way to reconcile nix-darwin with Determinate Nix (see
  # https://docs.determinate.systems/guides/nix-darwin/). Setting
  # `determinateNix.enable = true;` on a host (see
  # modules/aspects/hosts/ferrus.nix and lion.nix) disables nix-darwin's own
  # `/etc/nix/nix.conf` management (same effect as plain `nix.enable =
  # false;`) while additionally exposing `determinateNix.customSettings`,
  # which is written declaratively to `/etc/nix/nix.custom.conf` — the only
  # file Determinate Nix allows custom settings (like `trusted-users`) in.
  flake-file.inputs.determinate = {
    url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
