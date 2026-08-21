{
  lib,
  rustPlatform,
  secretspec,
}:

rustPlatform.buildRustPackage (_finalAttrs: {
  pname = "secretspec";
  version = "0.19.1";

  src = secretspec;

  buildAndTestSubdir = "secretspec";

  cargoHash = "sha256-7UEnT+iV78564cbNH45JC7hqwIKUTmxElIWhcvw+8h0=";

  doCheck = false;

  meta = {
    description = "Declarative secrets, every environment, any provider";
    homepage = "https://secretspec.dev";
    license = lib.licenses.asl20;
    mainProgram = "secretspec";
  };
})
