{
  fetchFromGitHub,
  lib,
  python312Packages,
}:
python312Packages.buildPythonApplication rec {
  pname = "headroom-ai";
  version = "unstable-2026-04-17";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "chopratejas";
    repo = "headroom";
    rev = "1039f66f67945998eac32940afdbeb5c9bd0297d";
    hash = "sha256-ciPjhveVlBKyWiLwm7SuKRaQ9/ddhcUmj1RTvJR5dj8=";
  };

  build-system = [ python312Packages.hatchling ];

  propagatedBuildInputs = with python312Packages; [
    click
    fastapi
    h2
    httpx
    litellm
    magika
    mcp
    onnxruntime
    openai
    opentelemetry-api
    pydantic
    rich
    safetensors
    sqlite-vec
    tiktoken
    torch
    transformers
    uvicorn
    watchdog
    websockets
    zstandard
  ];

  nativeBuildInputs = [ python312Packages.pythonRelaxDepsHook ];

  pythonRelaxDeps = [ "litellm" ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail \
        'headroom = "headroom.cli:main"' \
        $'headroom = "headroom.cli:main"\nheadroom-memory-mcp = "headroom.memory.mcp_server:main"'
  '';

  pythonImportsCheck = [
    "headroom"
    "headroom.memory.mcp_server"
  ];

  meta = {
    description = "Context optimization layer for LLM applications";
    homepage = "https://github.com/chopratejas/headroom";
    license = lib.licenses.asl20;
    mainProgram = "headroom";
    platforms = lib.platforms.unix;
  };
}
