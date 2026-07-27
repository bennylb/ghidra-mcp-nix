{
  ghidra,
  jdk21,
  lib,
  maven,
  release,
  src,
  stdenv,
  unzip,
  xmlstarlet,
  supportedSystems,
}:
let
  inherit (release.ghidraMcp) version requiredGhidraVersion;

  # Seed a fixed-output Maven repository with the Ghidra artifacts declared by
  # the pinned upstream pom.xml. Paths are discovered under ${ghidra}/lib/ghidra
  # by exact jar basename (${artifactId}.jar), not a hand-maintained map.
  seedGhidraMavenRepository = ''
    pomGhidraVersion="$(
      xmlstarlet sel \
        -N m=http://maven.apache.org/POM/4.0.0 \
        -t -v '/m:project/m:properties/m:ghidra.version' \
        pom.xml
    )"
    if [ -z "$pomGhidraVersion" ]; then
      echo "seedGhidraMavenRepository: pom.xml is missing <ghidra.version>" >&2
      exit 1
    fi
    if [ "$pomGhidraVersion" != "${requiredGhidraVersion}" ]; then
      echo "seedGhidraMavenRepository: pom ghidra.version is $pomGhidraVersion, expected ${requiredGhidraVersion}" >&2
      exit 1
    fi

    artifactsFile="$(mktemp)"
    xmlstarlet sel \
      -N m=http://maven.apache.org/POM/4.0.0 \
      -t -m '//m:dependency[m:groupId="ghidra"]' -v 'm:artifactId' -n \
      pom.xml \
      | sed '/^$/d' \
      > "$artifactsFile"

    if [ ! -s "$artifactsFile" ]; then
      echo "seedGhidraMavenRepository: no ghidra dependencies found in pom.xml" >&2
      exit 1
    fi

    duplicates="$(sort "$artifactsFile" | uniq -d)"
    if [ -n "$duplicates" ]; then
      echo "seedGhidraMavenRepository: duplicate ghidra artifactIds in pom.xml:" >&2
      echo "$duplicates" >&2
      exit 1
    fi

    while IFS= read -r artifact; do
      case "$artifact" in
        "" | *[!A-Za-z0-9._-]*)
          echo "seedGhidraMavenRepository: unsafe ghidra artifactId: $artifact" >&2
          exit 1
          ;;
      esac

      # Resolve by exact basename so we do not hardcode Ghidra's module layout.
      matchesFile="$(mktemp)"
      find "${ghidra}/lib/ghidra" -type f -name "''${artifact}.jar" > "$matchesFile"
      matchCount="$(wc -l < "$matchesFile" | tr -d ' ')"
      if [ "$matchCount" -ne 1 ]; then
        echo "seedGhidraMavenRepository: expected exactly one ''${artifact}.jar under ${ghidra}/lib/ghidra, found $matchCount" >&2
        if [ -s "$matchesFile" ]; then
          cat "$matchesFile" >&2
        fi
        exit 1
      fi
      jarPath="$(cat "$matchesFile")"
      rm -f "$matchesFile"

      artifactDirectory="$out/.m2/ghidra/''${artifact}/${requiredGhidraVersion}"
      mkdir -p "$artifactDirectory"
      cp "$jarPath" "$artifactDirectory/''${artifact}-${requiredGhidraVersion}.jar"
      cat > "$artifactDirectory/''${artifact}-${requiredGhidraVersion}.pom" <<EOF
    <project xmlns="http://maven.apache.org/POM/4.0.0">
      <modelVersion>4.0.0</modelVersion>
      <groupId>ghidra</groupId>
      <artifactId>''${artifact}</artifactId>
      <version>${requiredGhidraVersion}</version>
      <packaging>jar</packaging>
    </project>
    EOF
    done < "$artifactsFile"
    rm -f "$artifactsFile"
  '';
in
assert lib.assertMsg (ghidra.version == requiredGhidraVersion)
  "ghidra-mcp ${version} requires Ghidra ${requiredGhidraVersion}, but nixpkgs provides ${ghidra.version}";
maven.buildMavenPackage {
  pname = "ghidra-mcp-extension";
  inherit src version;

  mvnJdk = jdk21;
  mvnHash = "sha256-8dW+bX2YvHS3fSbWZKTefOftozaQumW9crLkgrsiJDY=";
  mvnGoal = "package";
  mvnParameters = "assembly:single -DskipTests";
  doCheck = false;

  mvnFetchExtraArgs = {
    postPatch = seedGhidraMavenRepository;
  };

  nativeBuildInputs = [
    unzip
    xmlstarlet
  ];

  installPhase = ''
    runHook preInstall

    extensionRoot="$out/lib/ghidra/Ghidra/Extensions"
    mkdir -p "$extensionRoot"
    unzip -q "target/GhidraMCP-${version}.zip" -d "$extensionRoot"

    test -f "$extensionRoot/GhidraMCP/extension.properties"
    test -f "$extensionRoot/GhidraMCP/lib/GhidraMCP-${version}.jar"
    grep -F "version=${requiredGhidraVersion}" "$extensionRoot/GhidraMCP/extension.properties"
    touch "$extensionRoot/GhidraMCP/.dbDirLock"

    runHook postInstall
  '';

  passthru = {
    releaseMetadata = release.ghidraMcp;
    inherit requiredGhidraVersion;
    sourceCommit = release.ghidraMcp.source.rev;
    tagObject = release.ghidraMcp.source.tagObject;
  };

  meta = {
    description = "Ghidra extension providing the GhidraMCP HTTP server";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
    platforms = supportedSystems;
  };
}
