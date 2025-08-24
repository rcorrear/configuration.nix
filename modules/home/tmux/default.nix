{
  lib,
  config,
  pkgs,
  ...
}:

let
  # Convention to access "our own" configuration
  fish_cfg = config.programs.fish;
  fzf_cfg = config.programs.fzf;
  tmux_cfg = config.programs.tmux;
in
{
  config.programs.fish.plugins = lib.mkIf (fish_cfg.enable && tmux_cfg.enable) [
    {
      name = "tmux";
      src = pkgs.fetchFromGitHub {
        owner = "budimanjojo";
        repo = "tmux.fish";
        rev = "87ef5c238b7fb133d7b49988c7c3fcb097953bd2";
        sha256 = "02pxx2rhc2by0j50n9k0vv51b29lpj5a4mjdca0rx5hpblvmdkbn";
        # date = "2023-03-26T02:15:51-07:00";
      };
    }
  ];

  config.programs.fzf.tmux = lib.mkIf (fzf_cfg.enable && tmux_cfg.enable) {
    enableShellIntegration = true;
    shellIntegrationOptions = [ "-d 40%" ];
  };
}
