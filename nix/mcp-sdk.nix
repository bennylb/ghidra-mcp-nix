{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  uv-dynamic-versioning,
  anyio,
  httpx,
  httpx-sse,
  jsonschema,
  pydantic,
  pydantic-settings,
  pyjwt,
  python-multipart,
  sse-starlette,
  starlette,
  typing-extensions,
  typing-inspection,
  uvicorn,
  release,
}:

buildPythonPackage {
  pname = "mcp";
  inherit (release.mcpSdk) version;
  pyproject = true;

  src = fetchFromGitHub {
    inherit (release.mcpSdk.source)
      owner
      repo
      rev
      hash
      ;
  };

  build-system = [
    hatchling
    uv-dynamic-versioning
  ];

  dependencies = [
    anyio
    httpx
    httpx-sse
    jsonschema
    pydantic
    pydantic-settings
    pyjwt
    python-multipart
    sse-starlette
    starlette
    typing-extensions
    typing-inspection
    uvicorn
  ]
  ++ pyjwt.optional-dependencies.crypto;

  # SDK library only; the bridge uses the mcp package API, not the mcp CLI.
  postInstall = ''
    rm "$out/bin/mcp"
  '';

  pythonImportsCheck = [ "mcp" ];

  doCheck = false;

  meta = {
    description = "Model Context Protocol SDK";
    homepage = "https://github.com/modelcontextprotocol/python-sdk";
    changelog = "https://github.com/modelcontextprotocol/python-sdk/releases/tag/${release.mcpSdk.source.tag}";
    license = lib.licenses.mit;
    # Pure Python library: real portability, not product support policy.
    platforms = lib.platforms.unix;
  };
}
