{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage rec {
  pname = "codex-multi-auth";
  version = "2.8.1";

  src = fetchFromGitHub {
    owner = "ndycode";
    repo = "codex-multi-auth";
    rev = "v${version}";
    hash = "sha256-7p6pPt5ZGWmf0qiXZLkM2KfBYIZCnljuBQbjsTyXzCM=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-G66QMXKgrxkfyVXZAWspsgegjNgPIE4EFxm/9s0HXfY=";

  meta = {
    description = "Multi-account OAuth manager for the official Codex CLI";
    homepage = "https://github.com/ndycode/codex-multi-auth";
    license = lib.licenses.mit;
    mainProgram = "codex-multi-auth";
    platforms = lib.platforms.all;
  };
}
