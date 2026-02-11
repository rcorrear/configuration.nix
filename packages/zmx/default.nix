{
  fetchFromGitHub,
  installShellFiles,
  lib,
  pkgs,
  stdenvNoCC,
  zig_0_15,
}:
let
  inherit (stdenvNoCC.hostPlatform) system;
  target = system;

  src = fetchFromGitHub {
    owner = "neurosnap";
    repo = "zmx";
    rev = "0dae6cf3a761236b2e5c75fda43d612cf9f679c4";
    hash = "sha256-c/jY5IvNvfIK5Tde52GjKjblsPkuZb0Qi4Yb9y5yaok=";
  };

  depsPath = pkgs.callPackage ./zig-deps.nix {
    zig = zig_0_15;
    name = "zmx-deps";
  };

  zmx-package = stdenvNoCC.mkDerivation {
    inherit src;
    name = "zmx";
    nativeBuildInputs = [
      installShellFiles
      zig_0_15
    ];
    buildPhase = ''
      export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
      export ZIG_CACHE_DIR="$TMPDIR/zig-cache"
      mkdir -p "$ZIG_GLOBAL_CACHE_DIR" "$ZIG_CACHE_DIR"
      ln -s ${depsPath} "$ZIG_GLOBAL_CACHE_DIR"/p
      ${zig_0_15}/bin/zig build \
        -Doptimize=ReleaseSafe \
        -Dtarget=${target} \
        --cache-dir "$ZIG_CACHE_DIR" \
        --global-cache-dir "$ZIG_GLOBAL_CACHE_DIR" \
        --prefix "$out"
    '';
    installPhase = ''
      installShellCompletion --cmd zmx \
        --bash <($out/bin/zmx completions bash) \
        --fish <($out/bin/zmx completions fish) \
        --zsh <($out/bin/zmx completions zsh)
    '';
    meta = {
      description = "Session persistence for terminal processes";
      homepage = "https://github.com/neurosnap/zmx";
      license = lib.licenses.mit;
    };
  };
in
zmx-package
