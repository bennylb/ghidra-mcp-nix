{ pkgs }:
let
  ghidra-mcp-extension = pkgs.callPackage ./extension.nix { };
  ghidra-mcp-bridge = pkgs.callPackage ./bridge.nix { };

  ghidra-with-mcp = pkgs.ghidra.withExtensions (_: [ ghidra-mcp-extension ]);
in
{
  inherit
    ghidra-mcp-bridge
    ghidra-mcp-extension
    ghidra-with-mcp
    ;
}
