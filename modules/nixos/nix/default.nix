{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    {
      documentation = {
        dev.enable = true;
        man = {
          enable = true;
          generateCaches = true;
        };
      };

      nix = {
        settings = {
          allow-import-from-derivation = lib.mkDefault true;
          auto-optimise-store = lib.mkDefault true;
          diff-hook = "${pkgs.nvd}/bin/nvd";
          run-diff-hook = lib.mkDefault true;
        };
      };
    }
  ];
}
