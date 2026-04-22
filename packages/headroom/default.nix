{
  ast-grep,
  fetchFromGitHub,
  lib,
  python312Packages,
}:
python312Packages.buildPythonApplication rec {
  pname = "headroom-ai";
  version = "0.9.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "chopratejas";
    repo = "headroom";
    rev = "5738339524fe1455d325adce87b2edbd1fa0ba5a";
    hash = "sha256-wW8lNaW52br9XMzpNBKwOYfSLVxT5/iozfSiyNM0usk=";
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

  nativeBuildInputs = [
    python312Packages.pythonRelaxDepsHook
  ];

  pythonRelaxDeps = [ "litellm" ];
  pythonRemoveDeps = [ "ast-grep-cli" ];
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [ ast-grep ])
  ];

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
