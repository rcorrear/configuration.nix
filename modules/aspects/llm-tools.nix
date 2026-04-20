{ inputs, lib, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
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
        llmPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        home.packages = [
          llmPkgs.agent-deck
          llmPkgs.backlog-md
          llmPkgs.claude-code
          llmPkgs.coderabbit-cli
          llmPkgs.code
          llmPkgs.codex
          llmPkgs.codex-acp
          llmPkgs.droid
          llmPkgs.opencode
          llmPkgs.openspec

          pkgs.rcorrear.rtk
          pkgs.rcorrear.headroom
          pkgs.bubblewrap
          pkgs.tmux # agent-deck requires tmux
        ];
        systemd.user.services = lib.optionalAttrs pkgs.stdenv.isLinux {
          headroom-proxy = {
            Unit = {
              Description = "Headroom local proxy";
              After = [ "default.target" ];
            };

            Service = {
              Environment = [
                "HEADROOM_WORKSPACE_DIR=${config.xdg.stateHome}/headroom"
              ];
              ExecStart = "${lib.getExe pkgs.rcorrear.headroom} proxy";
              Restart = "on-failure";
              RestartSec = 5;
            };

            Install.WantedBy = [ "default.target" ];
          };
        };
      };
  };
}
