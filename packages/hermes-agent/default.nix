{
  fetchFromGitHub,
  lib,
  makeWrapper,
  python312Packages,
  nodejs_22,
  ripgrep,
  git,
  openssh,
  ffmpeg,
}:
let
  matrixNioWithE2E = python312Packages."matrix-nio".overridePythonAttrs (old: {
    doCheck = false;
    propagatedBuildInputs =
      (old.propagatedBuildInputs or [ ])
      ++ (with python312Packages; [
        python312Packages."python-olm"
        peewee
        cachetools
        aiofiles
        atomicwrites
      ]);
  });
in
python312Packages.buildPythonApplication rec {
  pname = "hermes-agent";
  version = "0.5.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "NousResearch";
    repo = "hermes-agent";
    rev = "0b0c1b326c4db8c7a421473863c2a3fcbad76aea";
    hash = "sha256-zX8KMoGMtLjZ4DbZqrcefEqCWKACOKVABJtOg+SFiHg=";
  };

  build-system = [ python312Packages.setuptools ];

  propagatedBuildInputs = [
    python312Packages.openai
    python312Packages.anthropic
    python312Packages."python-dotenv"
    python312Packages.fire
    python312Packages.httpx
    python312Packages.rich
    python312Packages.tenacity
    python312Packages.pyyaml
    python312Packages.requests
    python312Packages.jinja2
    python312Packages.pydantic
    python312Packages."prompt-toolkit"
    python312Packages."firecrawl-py"
    python312Packages."edge-tts"
    python312Packages."faster-whisper"
    python312Packages.pyjwt
    python312Packages."simple-term-menu"
    python312Packages.mcp
    python312Packages."agent-client-protocol"
    matrixNioWithE2E
  ];

  nativeBuildInputs = [
    makeWrapper
    python312Packages.pythonRelaxDepsHook
  ];

  pythonRelaxDeps = [
    "tenacity"
    "requests"
    "firecrawl-py"
    "pyjwt"
  ];

  pythonRemoveDeps = [
    "parallel-web"
    "exa-py"
    "fal-client"
  ];

  postPatch = ''
    substituteInPlace tools/image_generation_tool.py \
      --replace-fail $'import fal_client\nfrom tools.debug_helpers import DebugSession' $'try:\n    import fal_client\nexcept ImportError:\n    fal_client = None\nfrom tools.debug_helpers import DebugSession'

    substituteInPlace tools/image_generation_tool.py \
      --replace-fail 'logger = logging.getLogger(__name__)' $'logger = logging.getLogger(__name__)\n\n\ndef _require_fal_client() -> None:\n    if fal_client is None:\n        raise RuntimeError("fal-client is not installed in this Hermes build")'

    substituteInPlace tools/image_generation_tool.py \
      --replace-fail '        logger.info("Upscaling image with Clarity Upscaler...")' $'        _require_fal_client()\n        logger.info("Upscaling image with Clarity Upscaler...")'

    substituteInPlace tools/image_generation_tool.py \
      --replace-fail '        logger.info("Generating %s image(s) with FLUX 2 Pro: %s", num_images, prompt[:80])' $'        _require_fal_client()\n        logger.info("Generating %s image(s) with FLUX 2 Pro: %s", num_images, prompt[:80])'

    substituteInPlace tools/image_generation_tool.py \
      --replace-fail $'        # Check if fal_client is available\n        import fal_client  # noqa: F401 — SDK presence check\n        return True' $'        # Check if fal_client is available\n        _require_fal_client()\n        return True'

    substituteInPlace tools/image_generation_tool.py \
      --replace-fail $'    # Check if fal_client is available\n    try:\n        import fal_client\n        print("✅ fal_client library available")\n    except ImportError:\n        print("❌ fal_client library not found")\n        print("Please install: pip install fal-client")\n        exit(1)' $'    # Check if fal_client is available\n    if fal_client is None:\n        print("❌ fal_client library not found")\n        print("This Hermes build omits fal-client support")\n        exit(1)\n    print("✅ fal_client library available")'
  '';

  postInstall = ''
    mkdir -p $out/share/hermes-agent
    cp -r skills $out/share/hermes-agent/skills

    for prog in $out/bin/hermes $out/bin/hermes-agent $out/bin/hermes-acp; do
      if [ -x "$prog" ]; then
        wrapProgram "$prog" \
          --set HERMES_BUNDLED_SKILLS "$out/share/hermes-agent/skills" \
          --suffix PATH : ${
            lib.makeBinPath [
              nodejs_22
              ripgrep
              git
              openssh
              ffmpeg
            ]
          }
      fi
    done
  '';

  pythonImportsCheck = [
    "agent"
    "gateway"
    "hermes_cli"
    "run_agent"
    "acp_adapter"
  ];

  meta = with lib; {
    description = "Hermes Agent packaged directly from GitHub sources";
    homepage = "https://github.com/NousResearch/hermes-agent";
    license = licenses.mit;
    mainProgram = "hermes";
    platforms = platforms.unix;
  };
}
