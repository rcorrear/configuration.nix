{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "jj-waltz";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "EzraCerpac";
    repo = "jj-waltz";
    rev = "v${version}";
    hash = "sha256-o1SAz0lTTPKi8bF+YfgzDDFt8/EyWRjLXos6Ia0eTu0=";
  };

  cargoHash = "sha256-LPHGArpBpSt7ViVzxlhPax0+p6yz0ShZkfJX1wPOLOU=";

  meta = {
    description = "Jujutsu workspace switcher inspired by Worktrunk";
    homepage = "https://github.com/EzraCerpac/jj-waltz";
    license = lib.licenses.mit;
    mainProgram = "jw";
    platforms = lib.platforms.unix;
  };
}
