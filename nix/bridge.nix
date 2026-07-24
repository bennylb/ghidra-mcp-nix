{
  fetchFromGitHub,
  lib,
  makeWrapper,
  python313,
  python313Packages,
  release,
  src,
  stdenvNoCC,
}:
let
  inherit (release.ghidraMcp) version;
  inherit (release) mcpSdk;

  mcp_1_28_1 = python313Packages.mcp.overridePythonAttrs (_old: {
    inherit (mcpSdk) version;
    src = fetchFromGitHub {
      inherit (mcpSdk.source)
        hash
        owner
        repo
        rev
        ;
    };
    doCheck = false;
  });

  pythonEnv = python313.withPackages (_: [
    mcp_1_28_1
    python313Packages.requests
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "ghidra-mcp-bridge";
  inherit src version;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm444 bridge_mcp_ghidra.py \
      "$out/share/ghidra-mcp/bridge_mcp_ghidra.py"
    makeWrapper "${pythonEnv}/bin/python" "$out/bin/bridge-mcp-ghidra" \
      --add-flags "$out/share/ghidra-mcp/bridge_mcp_ghidra.py"

    runHook postInstall
  '';

  passthru = {
    mcp = mcp_1_28_1;
    releaseMetadata = release.ghidraMcp;
    sourceCommit = release.ghidraMcp.source.rev;
    tagObject = release.ghidraMcp.source.tagObject;
  };

  meta = {
    description = "MCP stdio bridge for the GhidraMCP extension";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
    mainProgram = "bridge-mcp-ghidra";
    platforms = [ "aarch64-darwin" ];
  };
}
