{
  pkgs,
  supportedSystems,
  # Inline scripts allow arbitrary code execution through the MCP server.
  allowScripts ? true,
}:
let
  release = import ./release.nix;
  src = pkgs.callPackage ./source.nix { inherit release; };

  ghidra-mcp-extension = pkgs.callPackage ./extension.nix {
    inherit release src supportedSystems;
  };
  ghidra-mcp-bridge = pkgs.callPackage ./bridge.nix {
    inherit release src supportedSystems;
  };

  ghidra-tables-extension = pkgs.callPackage ./tables-extension.nix {
    inherit release supportedSystems;
  };

  mkGhidraWithMcp =
    extensions:
    (pkgs.ghidra.withExtensions (_: extensions)).overrideAttrs (oldAttrs: {
      # Re-wrap the launchers so the Ghidra JVM sees GHIDRA_MCP_ALLOW_SCRIPTS.
      # symlinkJoin bakes postBuild into buildCommand, so postBuild must not be overridden here.
      buildCommand =
        oldAttrs.buildCommand
        + pkgs.lib.optionalString allowScripts ''
          wrapProgram "$out/bin/ghidra" --set GHIDRA_MCP_ALLOW_SCRIPTS 1
          wrapProgram "$out/bin/ghidra-analyzeHeadless" --set GHIDRA_MCP_ALLOW_SCRIPTS 1
        '';
      passthru = (oldAttrs.passthru or { }) // {
        ghidraMcpExtension = ghidra-mcp-extension;
        ghidraMcpVersion = release.ghidraMcp.version;
        ghidraVersion = pkgs.ghidra.version;
        requiredGhidraVersion = release.ghidraMcp.requiredGhidraVersion;
      };
    });

  ghidra-with-mcp = mkGhidraWithMcp [ ghidra-mcp-extension ];
  ghidra-with-mcp-and-tables = mkGhidraWithMcp [
    ghidra-mcp-extension
    ghidra-tables-extension
  ];
in
{
  inherit
    ghidra-mcp-bridge
    ghidra-mcp-extension
    ghidra-tables-extension
    ghidra-with-mcp
    ghidra-with-mcp-and-tables
    ;
}
