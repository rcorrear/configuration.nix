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
        codexMultiHomeDir = "${config.xdg.stateHome}/codex-multi-home";
        huggingFaceDir = "${config.xdg.cacheHome}/huggingface";

        herdrPkgs = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system};
        llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        imports = [ ../../homes/modules/herdr.nix ];

        home = {
          packages = [
            llmPkgs.agent-deck
            llmPkgs.beads
            llmPkgs.beads-viewer
            llmPkgs.coderabbit-cli
            llmPkgs.codex
            llmPkgs.codex-acp
            llmPkgs.crit
            llmPkgs.opencode
            llmPkgs.openspec
            llmPkgs."open-code-review"

            pkgs.tmux # agent-deck requires tmux

            pkgs.rcorrear.codex-multi-auth
            # pkgs.rcorrear.headroom
            # pkgs.rcorrear.graphify
            pkgs.rcorrear.rtk
            # pkgs.python3Packages.huggingface-hub
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [
            pkgs.bubblewrap
          ];

          sessionVariables = {
            CODEX_MULTI_AUTH_DIR = codexMultiHomeDir;
            HF_HOME = huggingFaceDir;
            HUGGINGFACE_HUB_CACHE = "${config.home.sessionVariables.HF_HOME}/hub";
            TRANSFORMERS_CACHE = "${config.home.sessionVariables.HF_HOME}/transformers";
          };
        };

        programs.herdr = {
          enable = true;
          package = herdrPkgs.default;
          plugins = with pkgs.rcorrear.herdrPlugins; [
            jj-workspace
            worktree-setup
          ];
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
