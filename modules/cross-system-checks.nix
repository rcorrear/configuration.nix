{ lib, ... }:
let
  # Native Darwin hosts have this path; Linux cross-eval environments do not.
  isNativeDarwinHost = builtins.pathExists "/System/Library/CoreServices/SystemVersion.plist";
in
{
  perSystem =
    { pkgs, ... }:
    lib.mkIf (pkgs.stdenv.isDarwin && !isNativeDarwinHost) {
      # Suppress only known failing checks for Darwin when evaluated from non-Darwin hosts.
      checks.check-flake-file = lib.mkForce pkgs.emptyFile;
      checks.formatting = lib.mkForce pkgs.emptyFile;
      checks.treefmt = lib.mkForce pkgs.emptyFile;
    };
}
