{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "rtk";
  version = "0.45.0";

  src = fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${version}";
    hash = "sha256-uKf3GLabsZ094VviTXF90FohLiyXFqTV/hHlm/l+ICQ=";
  };

  cargoHash = "sha256-Vr1WKy+poeJnqjV7LvekC/jV1jolJDgxwNUp229EEWk=";

  doCheck = false; # `cargo test` fails in the Nix sandbox with tracker permission errors and missing `git` in `core::utils::tests::test_tool_exists_finds_git`.

  meta = {
    description = "CLI proxy that reduces LLM token consumption on common dev commands";
    homepage = "https://www.rtk-ai.app";
    license = lib.licenses.asl20;
    mainProgram = "rtk";
    platforms = lib.platforms.unix;
  };
}
