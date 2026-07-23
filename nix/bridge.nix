{
  fetchFromGitHub,
  lib,
  makeWrapper,
  python313,
  python313Packages,
  stdenvNoCC,
}:
let
  version = "5.14.2";
  src = import ./source.nix { inherit fetchFromGitHub lib; };

  mcp_1_28_1 = python313Packages.mcp.overridePythonAttrs (_old: {
    version = "1.28.1";
    src = fetchFromGitHub {
      owner = "modelcontextprotocol";
      repo = "python-sdk";
      tag = "v1.28.1";
      hash = "sha256-8nifuun7ShtniimsFr9gYPpjwZEM/5E51GDmZRxQGEc=";
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
    sourceCommit = "f4a1175b23f797cb19fb0f66c4ba19ff72684e72";
    tagObject = "bbfed0e02b64f0f93f6d448b75ca4d391d0dddca";
  };

  meta = {
    description = "MCP stdio bridge for the GhidraMCP extension";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
    mainProgram = "bridge-mcp-ghidra";
    platforms = [ "aarch64-darwin" ];
  };
}
