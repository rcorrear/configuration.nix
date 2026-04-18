{ inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.llm-tools = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
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

          pkgs.rcorrear.headroom
          pkgs.bubblewrap
          pkgs.tmux # agent-deck requires tmux
        ];
      };
  };
}
