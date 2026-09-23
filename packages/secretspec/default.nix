{
  lib,
  rustPlatform,
  secretspec,
}:

rustPlatform.buildRustPackage (_finalAttrs: {
  pname = "secretspec";
  version = "0.20.0";

  src = secretspec;

  buildAndTestSubdir = "secretspec";

  cargoHash = "sha256-XKKe65th0a1UwRo2qdwrWTZ6gY5JxzcAw4LfkZVv8MI=";

  doCheck = false;

  meta = {
    description = "Declarative secrets, every environment, any provider";
    homepage = "https://secretspec.dev";
    license = lib.licenses.asl20;
    mainProgram = "secretspec";
  };
})
