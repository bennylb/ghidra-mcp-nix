{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ghidra-mcp;
  system = pkgs.stdenv.hostPlatform.system;
  flakePackages = self.packages.${system};
  ghidraMcpExtension = flakePackages.ghidra-mcp-extension;
  ghidraMcpVersion = ghidraMcpExtension.version;
  inherit (ghidraMcpExtension) requiredGhidraVersion;
in
{
  options.programs.ghidra-mcp = {
    enable = lib.mkEnableOption "Ghidra with the GhidraMCP extension";

    enableCodexIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Configure Codex to start the packaged GhidraMCP bridge.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = flakePackages.ghidra-with-mcp;
      defaultText = lib.literalExpression "ghidra-mcp-nix.packages.\${pkgs.system}.ghidra-with-mcp";
      description = "Ghidra package composed with the GhidraMCP extension.";
    };

    bridgePackage = lib.mkOption {
      type = lib.types.package;
      default = flakePackages.ghidra-mcp-bridge;
      defaultText = lib.literalExpression "ghidra-mcp-nix.packages.\${pkgs.system}.ghidra-mcp-bridge";
      description = "Packaged GhidraMCP Python bridge.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      (lib.optional (cfg.package ? ghidraVersion) {
        assertion = cfg.package.ghidraVersion == requiredGhidraVersion;
        message = "programs.ghidra-mcp.package has ghidraVersion ${cfg.package.ghidraVersion}, but GhidraMCP ${ghidraMcpVersion} requires Ghidra ${requiredGhidraVersion}.";
      })
      ++ (lib.optional (cfg.package ? requiredGhidraVersion) {
        assertion = cfg.package.requiredGhidraVersion == requiredGhidraVersion;
        message = "programs.ghidra-mcp.package has requiredGhidraVersion ${cfg.package.requiredGhidraVersion}, but GhidraMCP ${ghidraMcpVersion} requires Ghidra ${requiredGhidraVersion}.";
      })
      ++ [
        {
          assertion = !cfg.enableCodexIntegration || config.programs.codex.enable;
          message = "programs.ghidra-mcp.enableCodexIntegration requires programs.codex.enable.";
        }
      ];

    home.packages = [
      cfg.package
      cfg.bridgePackage
    ];

    programs.codex.settings = lib.mkIf cfg.enableCodexIntegration {
      mcp_servers.ghidra = {
        command = "${cfg.bridgePackage}/bin/bridge-mcp-ghidra";
        args = [ ];
      };
    };
  };
}
