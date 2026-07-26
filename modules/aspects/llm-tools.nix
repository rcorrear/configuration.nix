{ inputs, lib, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
  };
  flake-file.inputs.herdr = {
    url = "github:ogulcancelik/herdr";
  };

  den.aspects.llm-tools = {
    includes = [ ];

    homeManager =
      {
        config,
        pkgs,
        ...
      }:
      let
        herdrPkgs = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system};
        llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        huggingFaceDir = "${config.xdg.cacheHome}/huggingface";
      in
      {
        imports = [ ../../homes/modules/herdr.nix ];

        home.packages = [
          llmPkgs.agent-deck
          llmPkgs.beads
          llmPkgs.beads-viewer
          llmPkgs.coderabbit-cli
          llmPkgs.code
          llmPkgs.codex
          llmPkgs.codex-acp
          llmPkgs.opencode
          llmPkgs.openspec

          pkgs.rcorrear.rtk
          # pkgs.rcorrear.headroom
          # pkgs.rcorrear.graphify
          pkgs.python3Packages.huggingface-hub
          pkgs.tmux # agent-deck requires tmux
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          pkgs.bubblewrap
        ];
        programs.herdr = {
          enable = true;
          package = herdrPkgs.default;
          plugins = with pkgs.rcorrear.herdrPlugins; [
            jj-workspace
            worktree-setup
          ];
        };
        home.sessionVariables = {
          HF_HOME = huggingFaceDir;
        };
        systemd.user.services = lib.optionalAttrs pkgs.stdenv.isLinux {
          # headroom-proxy = {
          #   Unit = {
          #     Description = "Headroom local proxy";
          #     After = [ "default.target" ];
          #   };

          #   Service = {
          #     Environment = [
          #       "HEADROOM_WORKSPACE_DIR=${config.xdg.stateHome}/headroom"
          #     ];
          #     ExecStart = "${lib.getExe pkgs.rcorrear.headroom} proxy --port 8787";
          #     Restart = "on-failure";
          #     RestartSec = 5;
          #   };

          #   Install.WantedBy = [ "default.target" ];
          # };
        };
      };
  };
}
