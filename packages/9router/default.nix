{
  fetchurl,
  lib,
  makeWrapper,
  nodejs_24,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "9router";
  version = "0.5.86";

  src = fetchurl {
    url = "https://registry.npmjs.org/9router/-/9router-${version}.tgz";
    hash = "sha256-z0qSVFpaWtrAHxBIMEFFWA2nEcr9Y67LA3VBgUbdAGQ=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/9router/app $out/bin
    cp -R app/.next-cli-build app/node_modules app/public app/src app/package.json app/server.js app/custom-server.js $out/lib/9router/app/
    substituteInPlace $out/lib/9router/app/server.js \
      --replace-fail 'process.chdir(__dirname)' 'process.chdir(process.env.DATA_DIR || __dirname)'
    substituteInPlace $out/lib/9router/app/.next-cli-build/server/chunks/4884.js \
      --replace-fail 'requireLogin:!0,requireApiKey:!0,tunnelDashboardAccess' \
      'requireLogin:!0,requireApiKey:"true"===process.env.REQUIRE_API_KEY,tunnelDashboardAccess'
    makeWrapper ${nodejs_24}/bin/node $out/bin/9router \
      --add-flags $out/lib/9router/app/custom-server.js

    runHook postInstall
  '';

  meta = {
    description = "Self-contained 9Router AI gateway server";
    homepage = "https://github.com/decolua/9router";
    license = lib.licenses.mit;
    mainProgram = "9router";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
  };
}
