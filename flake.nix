{
  description = "Reproducible GhidraMCP packages and Home Manager integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Supplies Ghidra and the extension's build tools, fixed to the Ghidra release
    # that ghidra-mcp targets. Must not follow a consumer's nixpkgs. Move this rev
    # together with requiredGhidraVersion in nix/release.nix.
    nixpkgs-ghidra.url = "github:NixOS/nixpkgs/319e4cebef10cbb636c6ea392137b52ad105336a";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-ghidra,
      home-manager,
      ...
    }:
    let
      # Product support policy: declared once at the flake composition edge.
      system = "aarch64-darwin";
      supportedSystems = [ system ];

      pkgs = import nixpkgs { inherit system; };
      ghidraPkgs = import nixpkgs-ghidra { inherit system; };
      ghidraMcp = pkgs.callPackage ./nix/packages.nix { inherit ghidraPkgs supportedSystems; };
    in
    {
      packages.${system} = {
        inherit (ghidraMcp)
          ghidra-mcp-bridge
          ghidra-mcp-extension
          ghidra-with-mcp
          ;
        default = ghidraMcp.ghidra-with-mcp;
      };

      apps.${system} = {
        ghidra = {
          type = "app";
          program = "${ghidraMcp.ghidra-with-mcp}/bin/ghidra";
          meta.description = "Launch Ghidra with the GhidraMCP extension";
        };
        ghidra-mcp-bridge = {
          type = "app";
          program = "${ghidraMcp.ghidra-mcp-bridge}/bin/bridge-mcp-ghidra";
          meta.description = "Run the GhidraMCP stdio bridge";
        };
        default = self.apps.${system}.ghidra;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          jdk21
          maven
          nixfmt
          python313
          statix
        ];
        JAVA_HOME = "${pkgs.jdk21}";
      };

      formatter.${system} = pkgs.nixfmt-tree;

      homeManagerModules.default = import ./modules/home-manager.nix {
        inherit self supportedSystems;
      };

      checks.${system} = import ./nix/checks.nix {
        inherit (pkgs) lib;
        inherit pkgs ghidraMcp supportedSystems;
        homeManagerLib = home-manager.lib;
        homeManagerModule = self.homeManagerModules.default;
      };
    };
}
