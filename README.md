# ghidra-mcp-nix

Reproducible Nix packages for
[`bethington/ghidra-mcp`](https://github.com/bethington/ghidra-mcp), including
Ghidra with the extension already available and the Python MCP bridge.

The current release targets Apple Silicon macOS, Ghidra 12.1.2, and
ghidra-mcp 5.14.2.

## Install with Home Manager

Add the flake and make it follow the same nixpkgs revision as the consuming
configuration:

```nix
inputs.ghidra-mcp-nix = {
  url = "github:bennylb/ghidra-mcp-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import and enable the module:

```nix
{
  imports = [ inputs.ghidra-mcp-nix.homeManagerModules.default ];

  programs.ghidra-mcp = {
    enable = true;
    enableCodexIntegration = true;
  };
}
```

`enableCodexIntegration` requires Home Manager's `programs.codex` module to be
enabled. It configures a local stdio MCP server named `ghidra`.

## Direct use

```console
nix run github:bennylb/ghidra-mcp-nix
nix run github:bennylb/ghidra-mcp-nix#ghidra-mcp-bridge -- --help
nix build github:bennylb/ghidra-mcp-nix#ghidra-mcp-extension
```

The main package uses `pkgs.ghidra.withExtensions`, so the extension remains
in the Nix store. It does not copy files into `~/Library/ghidra`.

## Activate the plugin

1. Launch the packaged Ghidra.
2. Open a program in CodeBrowser.
3. Open **File > Configure > Configure All Plugins** and enable
   **GhidraMCP**.
4. Select **Tools > GhidraMCP > Start MCP Server**.
5. Check `http://127.0.0.1:8089/check_connection`.

Plugin enablement and Ghidra tool preferences remain user state. Installing
and removing the extension itself is handled by Nix generations.

## Updating

Update the version, source commit, source hash, required Ghidra version, and
MCP SDK override together. Set the Maven dependency hash to `lib.fakeHash`,
build once to obtain the expected hash, then record it and rebuild offline.

```console
nix build .#ghidra-mcp-extension
nix flake check
```

The extension and bridge must always use the same upstream source commit.

## Dependency boundary

- Runtime: Ghidra and its wrapped Java runtime, Python, `mcp`, and `requests`.
- Build only: Maven, JDK 21, and the fixed Maven dependency repository.
- Excluded: debugger, tests, development dependencies, and `fun-doc`.

The upstream source and packaged extension are Apache-2.0 licensed. The Nix
packaging in this repository is MIT licensed.
