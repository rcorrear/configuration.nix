{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.secretspec = pkgs.testers.runNixOSTest (
        import "${self}/tests/secretspec/test.nix" {
          inherit pkgs self;
          secretspecPkg = pkgs.callPackage "${self}/packages/secretspec" {
            inherit (inputs) secretspec;
          };
        }
      );
    };
}
