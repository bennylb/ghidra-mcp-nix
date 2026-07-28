# ghidra-mcp-nix

Reproducible Nix packages for
[`bethington/ghidra-mcp`](https://github.com/bethington/ghidra-mcp): Ghidra with
the GhidraMCP extension available, plus the Python MCP stdio bridge.

This flake supports **`aarch64-darwin` only**. Current release: Ghidra 12.1.2,
ghidra-mcp 5.14.2.

## Install with Home Manager

Add the flake and follow the consumer's `nixpkgs`:

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
    enableCodexIntegration = true; # optional
  };
}
```

When enabled, the module installs both the composed Ghidra package and the
bridge package.

### Options

| Option | Role |
| --- | --- |
| `programs.ghidra-mcp.package` | Composed Ghidra package (default: flake `ghidra-with-mcp`) |
| `programs.ghidra-mcp.bridgePackage` | Bridge package (default: flake `ghidra-mcp-bridge`) |
| `programs.ghidra-mcp.enableCodexIntegration` | Configure Codex MCP server `ghidra` |

- Codex integration runs the selected `bridgePackage` as
  `${bridgePackage}/bin/bridge-mcp-ghidra`.
- `enableCodexIntegration` requires `programs.codex.enable`.
- If an overridden `package` provides `ghidraVersion` or
  `requiredGhidraVersion` passthru, those values are checked against the
  extension's required Ghidra version. Overrides that omit that metadata are
  not validated for it.

## Direct use

Published flake (consumers):

```console
nix run github:bennylb/ghidra-mcp-nix
nix run github:bennylb/ghidra-mcp-nix#ghidra-mcp-bridge -- --help
nix build github:bennylb/ghidra-mcp-nix#ghidra-mcp-extension
```

Local checkout (maintainers; `path:.` includes untracked files):

```console
nix run path:.
nix run path:.#ghidra-mcp-bridge -- --help
nix build path:.#ghidra-mcp-extension
```

## Packages and apps

| Output | Kind | Purpose |
| --- | --- | --- |
| `ghidra-mcp-bridge` | package / app | Python stdio bridge with a bridge-private MCP SDK runtime |
| `ghidra-mcp-extension` | package | Independently buildable Java extension |
| `ghidra-with-mcp` | package (also `default`) | Ghidra composed with the extension |
| `ghidra` / `default` | app | Launch composed Ghidra |
| `ghidra-mcp-bridge` | app | Run `bridge-mcp-ghidra` |

The extension stays in the Nix store via `pkgs.ghidra.withExtensions`. It is
not copied into the user's Ghidra profile (for example `~/Library/ghidra`).

## Activate the plugin

1. Launch the packaged Ghidra (`nix run …` or the Home Manager-installed binary).
2. Open a program in CodeBrowser.
3. Open **File > Configure > Configure All Plugins** and enable **GhidraMCP**.
4. Select **Tools > GhidraMCP > Start MCP Server**.
5. Check `http://127.0.0.1:8089/check_connection`.

Nix generations install and remove the extension immutably. Plugin enablement
and Ghidra tool preferences remain mutable user state.

## Updating releases

`nix/release.nix` is the single entrypoint for release metadata:

- ghidra-mcp version
- required Ghidra version
- ghidra-mcp immutable revision and source hash
- MCP SDK version, immutable revision, and source hash

Tag names and tag objects are provenance only; fetches use immutable commits.

`mvnHash` lives in `nix/extension.nix` because it fingerprints the fixed Maven
dependency repository, not release identity. When the extension dependency graph
changes:

1. Set `mvnHash` to `lib.fakeHash`.
2. Build once to obtain the expected hash.
3. Record that hash and rebuild offline.

The bridge and extension always share the same ghidra-mcp source from
`release.nix`. Do not bump version constants in `nix/mcp-sdk.nix`; that file
reads MCP SDK identity from `release.nix`.

Maintainer verification after a release bump:

```console
nix build path:.#ghidra-mcp-extension --print-build-logs
nix flake check path:. --print-build-logs
```

## Dependency boundaries

| Layer | Includes |
| --- | --- |
| Bridge runtime | Python and the bridge-private MCP SDK dependency closure |
| Composed Ghidra runtime | Ghidra and its required wrapped Java runtime |
| Extension build only | Maven, JDK 21, XML tooling, and the fixed Maven repository |

Maven and the build JDK are not runtime dependencies of the installed packages.

The upstream source and packaged extension are Apache-2.0 licensed. The Nix
packaging in this repository is MIT licensed.

## Checks and limits

`nix flake check` on `aarch64-darwin` runs:

| Check | Proves |
| --- | --- |
| `bridge-smoke` | Installed bridge imports, reports the packaged MCP distribution version, and accepts `--help` |
| `extension-layout` | Standalone extension has the expected layout and metadata |
| `extension-composition` | Composed Ghidra package contains the same extension artifacts |
| `home-manager-config` | Default Home Manager enablement evaluates/builds with the intended packages |
| `home-manager-codex-config` | Codex-enabled Home Manager config evaluates/builds with the intended packages and MCP command |
| `unsupported-system-message` | Unsupported-system module enablement produces the intended assertion message |

The extension package also runs the selected hermetic offline Java test set
(`com.xebyte.offline.*Test`) during its build.

**Not covered** by the package checks or `nix flake check`:

- live Ghidra application or GUI
- mutable program/project state
- external services
- performance environments
- Windows/PowerShell suites

`nix flake check` does **not** establish live plugin activation or end-to-end
MCP request behavior.
