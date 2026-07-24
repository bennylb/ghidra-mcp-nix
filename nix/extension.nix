{
  ghidra,
  jdk21,
  lib,
  maven,
  release,
  src,
  stdenv,
  unzip,
}:
let
  inherit (release.ghidraMcp) version;
  ghidraVersion = release.ghidraMcp.requiredGhidraVersion;

  ghidraJars = [
    {
      artifact = "Base";
      path = "Ghidra/Features/Base/lib/Base.jar";
    }
    {
      artifact = "Decompiler";
      path = "Ghidra/Features/Decompiler/lib/Decompiler.jar";
    }
    {
      artifact = "Docking";
      path = "Ghidra/Framework/Docking/lib/Docking.jar";
    }
    {
      artifact = "Generic";
      path = "Ghidra/Framework/Generic/lib/Generic.jar";
    }
    {
      artifact = "Project";
      path = "Ghidra/Framework/Project/lib/Project.jar";
    }
    {
      artifact = "SoftwareModeling";
      path = "Ghidra/Framework/SoftwareModeling/lib/SoftwareModeling.jar";
    }
    {
      artifact = "Utility";
      path = "Ghidra/Framework/Utility/lib/Utility.jar";
    }
    {
      artifact = "Gui";
      path = "Ghidra/Framework/Gui/lib/Gui.jar";
    }
    {
      artifact = "FileSystem";
      path = "Ghidra/Framework/FileSystem/lib/FileSystem.jar";
    }
    {
      artifact = "Graph";
      path = "Ghidra/Framework/Graph/lib/Graph.jar";
    }
    {
      artifact = "DB";
      path = "Ghidra/Framework/DB/lib/DB.jar";
    }
    {
      artifact = "Emulation";
      path = "Ghidra/Framework/Emulation/lib/Emulation.jar";
    }
    {
      artifact = "PDB";
      path = "Ghidra/Features/PDB/lib/PDB.jar";
    }
    {
      artifact = "FunctionID";
      path = "Ghidra/Features/FunctionID/lib/FunctionID.jar";
    }
    {
      artifact = "Help";
      path = "Ghidra/Framework/Help/lib/Help.jar";
    }
    {
      artifact = "Debugger-api";
      path = "Ghidra/Debug/Debugger-api/lib/Debugger-api.jar";
    }
    {
      artifact = "Framework-TraceModeling";
      path = "Ghidra/Debug/Framework-TraceModeling/lib/Framework-TraceModeling.jar";
    }
    {
      artifact = "Debugger-rmi-trace";
      path = "Ghidra/Debug/Debugger-rmi-trace/lib/Debugger-rmi-trace.jar";
    }
  ];

  seedGhidraMavenRepository = lib.concatMapStringsSep "\n" (
    jar:
    let
      artifactDirectory = "$out/.m2/ghidra/${jar.artifact}/${ghidraVersion}";
    in
    ''
      mkdir -p "${artifactDirectory}"
      cp "${ghidra}/lib/ghidra/${jar.path}" \
        "${artifactDirectory}/${jar.artifact}-${ghidraVersion}.jar"
      cat > "${artifactDirectory}/${jar.artifact}-${ghidraVersion}.pom" <<'EOF'
      <project xmlns="http://maven.apache.org/POM/4.0.0">
        <modelVersion>4.0.0</modelVersion>
        <groupId>ghidra</groupId>
        <artifactId>${jar.artifact}</artifactId>
        <version>${ghidraVersion}</version>
        <packaging>jar</packaging>
      </project>
      EOF
    ''
  ) ghidraJars;
in
assert lib.assertMsg (
  ghidra.version == ghidraVersion
) "ghidra-mcp ${version} requires Ghidra ${ghidraVersion}, but nixpkgs provides ${ghidra.version}";
maven.buildMavenPackage {
  pname = "ghidra-mcp-extension";
  inherit src version;

  mvnJdk = jdk21;
  mvnHash = "sha256-2bTvkFwGRFgZI+HgCORGlv5kc7iBaE5ukUc8PFvmtAY=";
  mvnGoal = "package";
  mvnParameters = "assembly:single -DskipTests";
  doCheck = false;

  mvnFetchExtraArgs = {
    postPatch = seedGhidraMavenRepository;
  };

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    extensionRoot="$out/lib/ghidra/Ghidra/Extensions"
    mkdir -p "$extensionRoot"
    unzip -q "target/GhidraMCP-${version}.zip" -d "$extensionRoot"

    test -f "$extensionRoot/GhidraMCP/extension.properties"
    test -f "$extensionRoot/GhidraMCP/lib/GhidraMCP-${version}.jar"
    grep -F "version=${ghidraVersion}" "$extensionRoot/GhidraMCP/extension.properties"
    touch "$extensionRoot/GhidraMCP/.dbDirLock"

    runHook postInstall
  '';

  passthru = {
    inherit ghidraVersion;
    releaseMetadata = release.ghidraMcp;
    requiredGhidraVersion = ghidraVersion;
    sourceCommit = release.ghidraMcp.source.rev;
    tagObject = release.ghidraMcp.source.tagObject;
  };

  meta = {
    description = "Ghidra extension providing the GhidraMCP HTTP server";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-darwin" ];
  };
}
