{ self, supportedSystems }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ghidra-mcp;
  system = pkgs.stdenv.hostPlatform.system;
  isSupported = lib.elem system supportedSystems;
  unsupportedMessage = "programs.ghidra-mcp is not supported on system ${system}; supported systems: ${lib.concatStringsSep ", " supportedSystems}";

  # Only resolve flake packages on supported systems so unsupported hosts fail
  # with the assertion message instead of a missing-attribute error.
  flakePackages = if isSupported then self.packages.${system} else null;
  ghidraMcpExtension = if isSupported then flakePackages.ghidra-mcp-extension else null;
  ghidraMcpVersion = if isSupported then ghidraMcpExtension.version else null;
  requiredGhidraVersion = if isSupported then ghidraMcpExtension.requiredGhidraVersion else null;
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
      default = if isSupported then flakePackages.ghidra-with-mcp else throw unsupportedMessage;
      defaultText = lib.literalExpression "ghidra-mcp-nix.packages.\${pkgs.system}.ghidra-with-mcp";
      description = "Ghidra package composed with the GhidraMCP extension.";
    };

    bridgePackage = lib.mkOption {
      type = lib.types.package;
      default = if isSupported then flakePackages.ghidra-mcp-bridge else throw unsupportedMessage;
      defaultText = lib.literalExpression "ghidra-mcp-nix.packages.\${pkgs.system}.ghidra-mcp-bridge";
      description = "Packaged GhidraMCP Python bridge.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = isSupported;
          message = unsupportedMessage;
        }
      ];
    })
    (lib.mkIf (cfg.enable && isSupported) {
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
    })
  ];
}
