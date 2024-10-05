{
  lib,
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
        };
      };
    }
  ];
}
