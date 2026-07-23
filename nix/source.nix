{
  fetchFromGitHub,
  lib,
}:
fetchFromGitHub {
  owner = "bethington";
  repo = "ghidra-mcp";
  rev = "f4a1175b23f797cb19fb0f66c4ba19ff72684e72";
  hash = "sha256-2EMETCttJAz53GQaJDHtegb8+T2cHKmHZVMPrV5Cwxc=";

  meta = {
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
  };
}
