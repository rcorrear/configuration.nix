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

  den.aspects.stylix-base = {
    includes = [ ];

    nixos =
      { config, pkgs, ... }:
      {
        imports = [ inputs.stylix.nixosModules.stylix ];
        inherit (mkStylixModule { inherit config pkgs; }) options config;
      };

    darwin =
      { config, pkgs, ... }:
      {
        imports = [ inputs.stylix.darwinModules.stylix ];
        inherit (mkStylixModule { inherit config pkgs; }) options config;
      };
  };
}
