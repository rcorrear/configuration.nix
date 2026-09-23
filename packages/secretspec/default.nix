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

  cargoHash = "sha256-8nYh1m2x/RrumiX/F2F2dRJc5YLArlBXGyTKmWGvY/w=";

  doCheck = false;

  meta = {
    description = "Declarative secrets, every environment, any provider";
    homepage = "https://secretspec.dev";
    license = lib.licenses.asl20;
    mainProgram = "secretspec";
  };
})
