{
  config,
  inputs,
  pkgs,
  ...
}:
let
  graphify = inputs.graphify.packages.${pkgs.system}.graphify;
  lifecycle = pkgs.callPackage ./packages/graphify/lifecycle.nix { inherit graphify; };
in
{
  packages = [
    pkgs.devenv
    pkgs.treefmt
    pkgs.babashka
    graphify
    lifecycle.build
    lifecycle.sync
  ];

  enterShell = ''
    if [ "''${CONFIGURATION_NIX_GRAPHIFY_AUTO_SYNC:-1}" != "0" ] &&
      git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      current_sha="$(git rev-parse HEAD)"
      graph_sha="$(
        ${pkgs.jq}/bin/jq -r '.source_sha // empty' \
          "${config.devenv.root}/graphify-out/build-metadata.json" 2>/dev/null || true
      )"
      graph_exact="$(
        ${pkgs.jq}/bin/jq -r '.exact // .working_tree_clean // false' \
          "${config.devenv.root}/graphify-out/build-metadata.json" 2>/dev/null || true
      )"
      if [ "$graph_sha" != "$current_sha" ] ||
        [ -n "$(git status --porcelain --untracked-files=all)" ] ||
        [ "$graph_exact" != "true" ]; then
        graphify-sync
      fi
    fi
  '';

  scripts.check.exec = ''
    nix fmt -- --fail-on-change "$@"
    exec prek run --all-files
  '';

  git-hooks.hooks = {
    flake-checker.enable = true;
    statix.enable = true;
    trufflehog.enable = true;
    zizmor.enable = true;
  };
}
