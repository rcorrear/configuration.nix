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
        headroomMemoryDir = "${config.xdg.stateHome}/headroom";
        headroomMemoryDbPath = "${headroomMemoryDir}/memory.db";
        huggingFaceDir = "${config.xdg.cacheHome}/huggingface";
      in
      {
        home.packages = [
          llmPkgs.agent-deck
          llmPkgs.backlog-md
          llmPkgs.beads
          llmPkgs.beads-rust
          llmPkgs.beads-viewer
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
          pkgs.python3Packages.huggingface-hub
          pkgs.tmux # agent-deck requires tmux
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          pkgs.bubblewrap
        ];
        home.sessionVariables = {
          HF_HOME = huggingFaceDir;
        };
        systemd.user.services = lib.optionalAttrs pkgs.stdenv.isLinux {
          headroom-proxy = {
            Unit = {
              Description = "Headroom local proxy";
              After = [ "default.target" ];
            };

            Service = {
              Environment = [
                "HF_HOME=${huggingFaceDir}"
              ];
              ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p ${headroomMemoryDir} ${huggingFaceDir}";
              ExecStart = "${lib.getExe pkgs.rcorrear.headroom} proxy --memory --memory-db-path ${headroomMemoryDbPath}";
              Restart = "on-failure";
              RestartSec = 5;
            };

            Install.WantedBy = [ "default.target" ];
          };
        };
      };
  };
}
