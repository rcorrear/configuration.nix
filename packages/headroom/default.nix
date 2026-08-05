{
  ast-grep,
  cargo,
  fetchFromGitHub,
  lib,
  onnxruntime,
  python312Packages,
  rustc,
  rustPlatform,
}:
python312Packages.buildPythonApplication rec {
  pname = "headroom-ai";
  version = "0.34.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "headroomlabs-ai";
    repo = "headroom";
    tag = "v${version}";
    hash = "sha256-A04h+wTlGBZVXW6ujb8bYdtM2Y16SbntwnNy48qaA7g=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit pname version src;
    hash = "sha256-botF67LFoaRf7JpQOocAbT0fzvwe8Pgjp0Krz/dLNxg=";
  };

  build-system = [ rustPlatform.maturinBuildHook ];

  buildInputs = [ onnxruntime ];

  env = {
    ORT_STRATEGY = "system";
    ORT_LIB_LOCATION = "${onnxruntime}/lib";
    ORT_INCLUDE_LOCATION = "${onnxruntime.dev}/include/onnxruntime";
    ORT_PREFER_DYNAMIC_LINK = "1";
  };

  dependencies = with python312Packages; [
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
    transformers
    uvicorn
    watchdog
    websockets
    zstandard
  ];

  nativeBuildInputs = [
    cargo
    python312Packages.pythonRelaxDepsHook
    rustc
    rustPlatform.cargoSetupHook
  ];

  pythonRelaxDeps = [ "litellm" ];
  pythonRemoveDeps = [ "ast-grep-cli" ];
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail \
        'headroom = "headroom.cli:main"' \
        $'headroom = "headroom.cli:main"\nheadroom-memory-mcp = "headroom.memory.mcp_server:main"'

    substituteInPlace headroom/cli/wrap.py \
      --replace-fail \
        '    proxy_env["PYTHONIOENCODING"] = "utf-8"' \
        $'    proxy_env["PYTHONIOENCODING"] = "utf-8"\n    python_paths = [p for p in sys.path if "site-packages" in p]\n    if python_paths:\n        existing_pythonpath = proxy_env.get("PYTHONPATH")\n        proxy_env["PYTHONPATH"] = os.pathsep.join(\n            python_paths + ([existing_pythonpath] if existing_pythonpath else [])\n        )'

    substituteInPlace headroom/cli/wrap.py \
      --replace-fail \
        '    python_bin = sys.executable.replace("\\", "/")' \
        '    python_bin = str(Path(sys.argv[0]).with_name("headroom-memory-mcp")).replace("\\", "/")'

    substituteInPlace headroom/cli/wrap.py \
      --replace-fail \
        "        f'args = [\"-m\", \"headroom.memory.mcp_server\", \"--user\", \"{user_id}\"]\n'" \
        "        f'args = [\"--user\", \"{user_id}\"]\n'"
  '';
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [ ast-grep ])
  ];

  pythonImportsCheck = [
    "headroom"
    "headroom._core"
    "headroom.memory.mcp_server"
  ];

  meta = {
    description = "Context optimization layer for LLM applications";
    homepage = "https://github.com/headroomlabs-ai/headroom";
    license = lib.licenses.asl20;
    mainProgram = "headroom";
    platforms = lib.platforms.unix;
  };
}
