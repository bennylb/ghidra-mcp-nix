{
  lib,
  pkgs,
  ghidraMcp,
  homeManagerLib,
  homeManagerModule,
  supportedSystems,
}:
let
  inherit (ghidraMcp)
    ghidra-mcp-bridge
    ghidra-mcp-extension
    ghidra-with-mcp
    ;

  extensionVersion = ghidra-mcp-extension.version;
  inherit (ghidra-mcp-extension) requiredGhidraVersion;

  extensionRootSuffix = "lib/ghidra/Ghidra/Extensions/GhidraMCP";
  extensionJarName = "GhidraMCP-${extensionVersion}.jar";

  hasPackage = package: packages: lib.any (candidate: candidate.outPath == package.outPath) packages;

  baseHomeManagerModules = [
    homeManagerModule
    {
      home = {
        username = "ghidra-mcp-test";
        homeDirectory = "/Users/ghidra-mcp-test";
        stateVersion = "24.11";
      };
    }
  ];

  mkHomeManagerConfiguration =
    extraModules:
    homeManagerLib.homeManagerConfiguration {
      inherit pkgs;
      modules = baseHomeManagerModules ++ extraModules;
    };

  assertHomePackagesAndNoGhidraHome =
    checkName: config:
    assert lib.assertMsg (hasPackage ghidra-with-mcp config.home.packages)
      "${checkName}: ghidra-with-mcp is missing from home.packages";
    assert lib.assertMsg (hasPackage ghidra-mcp-bridge config.home.packages)
      "${checkName}: ghidra-mcp-bridge is missing from home.packages";
    assert lib.assertMsg (
      !(config.home.sessionVariables ? GHIDRA_HOME)
    ) "${checkName}: home.sessionVariables must not contain GHIDRA_HOME";
    true;

  # Derivation-only: assert about hm.config at each call site before invoking.
  mkHomeManagerActivationCheck =
    name: hm:
    pkgs.runCommand name
      {
        inherit (hm) activationPackage;
      }
      ''
        set -euo pipefail
        test -d "$activationPackage" || {
          echo "${name}: activation package was not built" >&2
          exit 1
        }
        mkdir -p "$out"
        ln -s "$activationPackage" "$out/activation-package"
        echo ok > "$out/result"
      '';

  # Unsupported host must fail with a direct compatibility message, not
  # "attribute '…' missing" from self.packages.${system}.
  unsupportedSystem = "x86_64-linux";
  unsupportedMessage = "programs.ghidra-mcp is not supported on system ${unsupportedSystem}; supported systems: ${lib.concatStringsSep ", " supportedSystems}";

  unsupportedPkgs = pkgs // {
    stdenv = pkgs.stdenv // {
      hostPlatform = pkgs.stdenv.hostPlatform // {
        system = unsupportedSystem;
      };
    };
  };

  unsupportedSystemEval = lib.evalModules {
    specialArgs = {
      pkgs = unsupportedPkgs;
    };
    modules = [
      (pkgs.path + "/nixos/modules/misc/assertions.nix")
      # Stub Home Manager option trees so the module can be evaluated alone.
      {
        options.home.packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
        };
        options.programs.codex = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          settings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
          };
        };
      }
      (import ../modules/home-manager.nix {
        # Empty package set: unsupported path must not force package lookup.
        self = {
          packages = { };
        };
        inherit supportedSystems;
      })
      {
        programs.ghidra-mcp.enable = true;
      }
    ];
  };

  failedUnsupportedAssertions = builtins.filter (a: !a.assertion) unsupportedSystemEval.config.assertions;
in
assert lib.assertMsg (lib.any (a: a.message == unsupportedMessage) failedUnsupportedAssertions)
  "unsupported-system-message: expected assertion ${unsupportedMessage}, got ${builtins.toJSON failedUnsupportedAssertions}";
{
  bridge-smoke =
    let
      pythonEnv = pkgs.python313.withPackages (_: [ ghidra-mcp-bridge.passthru.mcp ]);
      expectedMcpVersion = ghidra-mcp-bridge.passthru.mcp.version;
    in
    pkgs.runCommand "bridge-smoke"
      {
        nativeBuildInputs = [ pythonEnv ];
        bridge = ghidra-mcp-bridge;
        inherit expectedMcpVersion;
      }
      ''
        set -euo pipefail

        mcp_version="$(python -c 'import importlib.metadata; print(importlib.metadata.version("mcp"))')"
        if [ "$mcp_version" != "$expectedMcpVersion" ]; then
          echo "bridge-smoke: expected installed mcp version $expectedMcpVersion, got $mcp_version" >&2
          exit 1
        fi

        bridge_script="$bridge/share/ghidra-mcp/bridge_mcp_ghidra.py"
        test -f "$bridge_script" || {
          echo "bridge-smoke: installed bridge script missing at $bridge_script" >&2
          exit 1
        }

        python - "$bridge_script" <<'PY'
        import importlib.util
        import sys
        from pathlib import Path

        path = Path(sys.argv[1])
        spec = importlib.util.spec_from_file_location("bridge_mcp_ghidra", path)
        if spec is None or spec.loader is None:
            raise SystemExit(f"bridge-smoke: failed to create import spec for {path}")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        PY

        "$bridge/bin/bridge-mcp-ghidra" --help >/dev/null

        mkdir -p "$out"
        echo ok > "$out/result"
      '';

  extension-layout =
    pkgs.runCommand "extension-layout"
      {
        nativeBuildInputs = [ pkgs.unzip ];
        extension = ghidra-mcp-extension;
        inherit extensionVersion requiredGhidraVersion extensionJarName;
      }
      ''
        set -euo pipefail

        root="$extension/${extensionRootSuffix}"
        jar="$root/lib/$extensionJarName"

        test -f "$root/Module.manifest" || {
          echo "extension-layout: Module.manifest missing under $root" >&2
          exit 1
        }
        test -f "$root/extension.properties" || {
          echo "extension-layout: extension.properties missing under $root" >&2
          exit 1
        }
        test -f "$jar" || {
          echo "extension-layout: versioned JAR missing at $jar" >&2
          exit 1
        }

        grep -Fx "name=GhidraMCP" "$root/extension.properties" >/dev/null || {
          echo "extension-layout: extension.properties must contain exact line name=GhidraMCP" >&2
          exit 1
        }
        grep -Fx "version=$requiredGhidraVersion" "$root/extension.properties" >/dev/null || {
          echo "extension-layout: extension.properties must contain exact line version=$requiredGhidraVersion" >&2
          exit 1
        }

        unzip -p "$jar" META-INF/MANIFEST.MF | tr -d '\r' > manifest.mf

        for required in \
          "Plugin-Class: com.xebyte.GhidraMCPPlugin" \
          "Plugin-Name: GhidraMCP" \
          "Plugin-Version: $extensionVersion" \
          "Java-Version: 21"
        do
          grep -F "$required" manifest.mf >/dev/null || {
            echo "extension-layout: JAR MANIFEST.MF missing required entry: $required" >&2
            exit 1
          }
        done

        mkdir -p "$out"
        echo ok > "$out/result"
      '';

  extension-composition =
    pkgs.runCommand "extension-composition"
      {
        composed = ghidra-with-mcp;
        extension = ghidra-mcp-extension;
        inherit extensionJarName;
      }
      ''
        set -euo pipefail

        composed_root="$composed/${extensionRootSuffix}"
        extension_root="$extension/${extensionRootSuffix}"
        composed_jar="$composed_root/lib/$extensionJarName"
        extension_jar="$extension_root/lib/$extensionJarName"

        test -f "$composed_root/Module.manifest" || {
          echo "extension-composition: Module.manifest missing from ghidra-with-mcp extension tree" >&2
          exit 1
        }
        test -f "$composed_root/extension.properties" || {
          echo "extension-composition: extension.properties missing from ghidra-with-mcp extension tree" >&2
          exit 1
        }
        test -f "$composed_jar" || {
          echo "extension-composition: versioned JAR missing from ghidra-with-mcp at $composed_jar" >&2
          exit 1
        }

        cmp "$composed_root/extension.properties" "$extension_root/extension.properties" || {
          echo "extension-composition: composed extension.properties differs from ghidra-mcp-extension" >&2
          exit 1
        }
        cmp "$composed_jar" "$extension_jar" || {
          echo "extension-composition: composed JAR differs from ghidra-mcp-extension" >&2
          exit 1
        }

        mkdir -p "$out"
        echo ok > "$out/result"
      '';

  home-manager-config =
    let
      name = "home-manager-config";
      hm = mkHomeManagerConfiguration [
        {
          programs.ghidra-mcp.enable = true;
        }
      ];
    in
    assert assertHomePackagesAndNoGhidraHome name hm.config;
    mkHomeManagerActivationCheck name hm;

  home-manager-codex-config =
    let
      name = "home-manager-codex-config";
      hm = mkHomeManagerConfiguration [
        {
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
      expected = {
        command = "${ghidra-mcp-bridge}/bin/bridge-mcp-ghidra";
        args = [ ];
      };
      actual = hm.config.programs.codex.settings.mcp_servers.ghidra;
    in
    assert assertHomePackagesAndNoGhidraHome name hm.config;
    assert lib.assertMsg (actual == expected)
      "${name}: programs.codex.settings.mcp_servers.ghidra must equal ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
    mkHomeManagerActivationCheck name hm;

  unsupported-system-message = pkgs.runCommand "unsupported-system-message" { } ''
    set -euo pipefail
    mkdir -p "$out"
    printf '%s\n' ${lib.escapeShellArg unsupportedMessage} > "$out/message"
    echo ok > "$out/result"
  '';
}
