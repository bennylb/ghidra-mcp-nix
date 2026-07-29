{
  lib,
  python313Packages,
  release,
  src,
  supportedSystems,
}:
let
  inherit (release.ghidraMcp) version;

  mcp = python313Packages.callPackage ./mcp-sdk.nix { inherit release; };
in
python313Packages.buildPythonApplication {
  pname = "ghidra-mcp-bridge";
  inherit src version;
  pyproject = true;

  build-system = [ python313Packages.hatchling ];
  dependencies = [ mcp ];
  doCheck = false;
  pythonImportsCheck = [ "bridge_mcp_ghidra" ];

  passthru = {
    inherit mcp;
    releaseMetadata = release.ghidraMcp;
    sourceCommit = release.ghidraMcp.source.rev;
    tagObject = release.ghidraMcp.source.tagObject;
  };

  meta = {
    description = "MCP stdio bridge for the GhidraMCP extension";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
    mainProgram = "bridge-mcp-ghidra";
    platforms = supportedSystems;
  };
}
