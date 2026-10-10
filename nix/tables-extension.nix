{
  fetchFromGitHub,
  ghidra,
  gradle_8,
  jdk21,
  lib,
  release,
  stdenv,
  unzip,
  supportedSystems,
}:
let
  inherit (release.ghidraMcp) requiredGhidraVersion;
  inherit (release.ghidraTables) source;
in
assert lib.assertMsg (
  ghidra.version == requiredGhidraVersion
) "ghidra-tables requires Ghidra ${requiredGhidraVersion}, but nixpkgs provides ${ghidra.version}";
stdenv.mkDerivation {
  pname = "ghidra-tables-extension";
  version = builtins.substring 0 7 source.rev;

  src = fetchFromGitHub {
    inherit (source)
      hash
      owner
      repo
      rev
      ;
  };

  nativeBuildInputs = [
    gradle_8
    jdk21
    unzip
  ];

  # The only external Gradle dependency is junit (tests), which is not resolved
  # by buildExtension, so no dependency lock is needed. Tests are skipped.
  env.GHIDRA_INSTALL_DIR = "${ghidra}/lib/ghidra";

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    export GRADLE_USER_HOME="$TMPDIR/gradle-home"
    gradle --offline --no-daemon buildExtension
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    extensionRoot="$out/lib/ghidra/Ghidra/Extensions"
    mkdir -p "$extensionRoot"
    unzip -q dist/*.zip -d "$extensionRoot"

    test -f "$extensionRoot/GhidraTables/extension.properties"
    test -f "$extensionRoot/GhidraTables/lib/GhidraTables.jar"
    grep -Fx "version=${requiredGhidraVersion}" "$extensionRoot/GhidraTables/extension.properties"
    touch "$extensionRoot/GhidraTables/.dbDirLock"

    runHook postInstall
  '';

  passthru = { inherit requiredGhidraVersion; };

  meta = {
    description = "Ghidra extension for finding and editing Denso ECU calibration tables";
    homepage = "https://github.com/daskey/GhidraTables";
    platforms = supportedSystems;
  };
}
