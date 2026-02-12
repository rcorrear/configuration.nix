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
          llmPkgs.claude-code
          llmPkgs.opencode
          llmPkgs.codex
        ];
      };
  };
}
