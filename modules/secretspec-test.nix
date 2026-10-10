{ self, ... }:
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        secretspec = pkgs.testers.runNixOSTest (
          import "${self}/tests/secretspec/test.nix" {
            inherit pkgs self;
            secretspecPkg = config.packages.secretspec;
          }
        );
      };
    };
}
