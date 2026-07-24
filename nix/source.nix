{
  fetchFromGitHub,
  lib,
  release,
}:
let
  inherit (release.ghidraMcp) source;
in
fetchFromGitHub {
  inherit (source)
    hash
    owner
    repo
    rev
    ;

  meta = {
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = lib.licenses.asl20;
  };
}
