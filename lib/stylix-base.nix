# Shared Stylix theming configuration
#
# This module provides common Stylix settings with options for customization.
# The actual Stylix module (darwinModules.stylix or nixosModules.stylix) must
# be imported separately by each host.
#
# Options:
#   aspects.stylix.theme    - Base16 theme name (default: "rose-pine")
#   aspects.stylix.image    - Optional wallpaper (NixOS only, default: null)
#
{
  config,
  lib,
  pkgs,
  ...
}:
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
        pkgs.fetchurl {
          url = "https://example.com/wallpaper.jpg";
          sha256 = "...";
        }
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = builtins.pathExists themePath;
        message = "Stylix theme '${cfg.theme}' not found at ${themePath}. Check aspects.stylix.theme.";
      }
    ];

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
}
