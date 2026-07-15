{ inputs, lib, ... }:
let
  mkStylixModule =
    { config, pkgs, ... }:
    let
      cfg = config.aspects.stylix;
      themePath = "${pkgs.base16-schemes}/share/themes/${cfg.theme}.yaml";
    in
    {
      options.aspects.stylix = {
        theme = lib.mkOption {
          type = lib.types.str;
          default = "rose-pine";
          description = "Base16 theme name from base16-schemes";
          example = "catppuccin-mocha";
        };

        image = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Optional wallpaper image (typically used on NixOS)";
          example = lib.literalExpression ''
            ./wallpaper.jpg
          '';
        };
      };

      config = {
        stylix = {
          enable = true;
          base16Scheme = themePath;
          fonts.monospace = {
            name = "CaskaydiaCove Nerd Font Mono";
            package = pkgs.nerd-fonts.caskaydia-cove;
          };
          polarity = "dark";
        }
        // lib.optionalAttrs (cfg.image != null) { inherit (cfg) image; };
      };
    };
in
{
  flake-file.inputs.stylix = {
    url = "github:danth/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.stylix = {
    includes = [ ];

    nixos =
      { config, pkgs, ... }:
      let
        stylixModule = mkStylixModule { inherit config pkgs; };
      in
      {
        imports = [ inputs.stylix.nixosModules.stylix ];
        inherit (stylixModule) options;
        config = lib.mkMerge [
          stylixModule.config
          {
            # See the note on the `darwin` key below: the `homeManager` key
            # of this aspect is the sole importer of stylix's home-manager
            # module, so the OS module's own auto-propagation into embedded
            # home-manager instances must be off to avoid a double import.
            stylix.homeManagerIntegration.autoImport = false;
          }
        ];
      };

    darwin =
      { config, pkgs, ... }:
      let
        stylixModule = mkStylixModule { inherit config pkgs; };
      in
      {
        imports = [ inputs.stylix.darwinModules.stylix ];
        inherit (stylixModule) options;
        config = lib.mkMerge [
          stylixModule.config
          {
            # Stylix's own OS modules auto-propagate `stylix.*` into the
            # *embedded* home-manager instance
            # (`home-manager.users.<name>`) via
            # `home-manager.sharedModules`, copying values with
            # `lib.mkDefault`. Disabled here because this aspect's
            # `provides.home` sub-aspect below (included by the rcorrear
            # user aspect for every `homeManager`-class target, both the
            # embedded and the *standalone* `homeConfigurations` entities
            # built by `nh home switch`) already imports stylix's
            # home-manager module directly and uniformly. Leaving
            # auto-propagation on as well would import that module twice
            # into the embedded instance and fail to evaluate (its
            # read-only derived options, like `stylix.base16`, can only be
            # defined once).
            stylix.homeManagerIntegration.autoImport = false;
          }
        ];
      };

    # See the `autoImport = false;` notes on the OS keys above: this is the
    # sole importer of stylix's home-manager module for every
    # `homeManager`-class target, standalone or embedded alike, so both get
    # identically themed regardless of which one is activated (`nh home
    # switch` vs `nh darwin switch`).
    #
    # Exposed as a `provides` sub-aspect (rather than a `homeManager` key on
    # the main aspect) so user aspects can pull in just the home-manager
    # theming (`den.aspects.stylix._.home`, see
    # modules/aspects/users/rcorrear.nix) without also dragging the OS
    # classes above onto every (headless) host the user is declared on.
    provides.home.homeManager =
      { config, pkgs, ... }:
      let
        stylixModule = mkStylixModule { inherit config pkgs; };
      in
      {
        imports = [ inputs.stylix.homeModules.stylix ];
        inherit (stylixModule) options;
        config = lib.mkMerge [
          stylixModule.config
          {
            # Keep starship's own literal ANSI color names (see
            # homes/all-platforms/rcorrear/starship.nix) resolving
            # through the terminal's palette rather than having stylix
            # inject its own `palette`/hex overrides into starship's
            # config, which `stylix.autoEnable` would otherwise do as
            # soon as `programs.starship.enable` is on.
            stylix.targets.starship.enable = false;
          }
        ];
      };
  };
}
