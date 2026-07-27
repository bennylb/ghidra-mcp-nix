{
  description = "Reproducible GhidraMCP packages and Home Manager integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      ghidraMcp = pkgs.callPackage ./nix/packages.nix { };
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

      homeManagerModules.default = import ./modules/home-manager.nix { inherit self; };

      checks.${system} = {
        inherit (ghidraMcp)
          ghidra-mcp-bridge
          ghidra-mcp-extension
          ghidra-with-mcp
          ;

        home-manager =
          (home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              self.homeManagerModules.default
              {
                home = {
                  username = "ghidra-mcp-test";
                  homeDirectory = "/Users/ghidra-mcp-test";
                  stateVersion = "24.11";
                };
                programs.ghidra-mcp.enable = true;
              }
            ];
          }).activationPackage;

        home-manager-codex =
          (home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              self.homeManagerModules.default
              {
                home = {
                  username = "ghidra-mcp-test";
                  homeDirectory = "/Users/ghidra-mcp-test";
                  stateVersion = "24.11";
                };
                programs = {
                  codex = {
                    enable = true;
                    package = null;
                  };
                  ghidra-mcp = {
                    enable = true;
                    enableCodexIntegration = true;
                  };
                };
              }
            ];
          }).activationPackage;
      };
    };
}
