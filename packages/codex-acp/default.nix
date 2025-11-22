{
  lib,
  pkgs,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "codex-acp";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "codex-acp";
    rev = "v0.3.0";
    sha256 = "sha256-t/QqRCEMuM1MGbi5P5lPuZw3SjyayLffG04mN//Mupk=";
  };

  cargoHash = "sha256-TD4iADzLIyv65JcaPm1LnvXipSaCRJMF67D/sDa/lBU=";

  nativeBuildInputs = [
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.openssl
  ];

  doInstallCheck = true;

  meta = {
    description = "ACP adapter for Codex";
    homepage = "https://github.com/zed-industries/codex-acp";
    changelog = "https://github.com/zed-industries/codex-acp/releases/tag/v${version}";
    license = lib.licenses.asl20;
    # maintainers = with lib.maintainers; [ fab ];
    mainProgram = "codex-acp";
  };
}
