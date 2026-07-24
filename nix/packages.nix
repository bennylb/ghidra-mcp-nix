{ pkgs }:
let
  release = import ./release.nix;
  src = pkgs.callPackage ./source.nix { inherit release; };

  ghidra-mcp-extension = pkgs.callPackage ./extension.nix { inherit release src; };
  ghidra-mcp-bridge = pkgs.callPackage ./bridge.nix { inherit release src; };

  ghidra-with-mcp-base = pkgs.ghidra.withExtensions (_: [ ghidra-mcp-extension ]);
  ghidra-with-mcp = ghidra-with-mcp-base.overrideAttrs (oldAttrs: {
    passthru = (oldAttrs.passthru or { }) // {
      ghidraMcpExtension = ghidra-mcp-extension;
      ghidraMcpVersion = release.ghidraMcp.version;
      requiredGhidraVersion = release.ghidraMcp.requiredGhidraVersion;
    };
  });
in
{
  inherit
    ghidra-mcp-bridge
    ghidra-mcp-extension
    ghidra-with-mcp
    ;
}
