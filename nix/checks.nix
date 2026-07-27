{
  lib,
  pkgs,
  ghidraMcp,
  homeManagerLib,
  homeManagerModule,
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

  mkHomeManagerCheck =
    {
      name,
      extraModules ? [ ],
      extraAssertions ? (_config: true),
    }:
    let
      hm = mkHomeManagerConfiguration extraModules;
      evaluated =
        assert assertHomePackagesAndNoGhidraHome name hm.config;
        assert extraAssertions hm.config;
        true;
    in
    assert evaluated;
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
in
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

  home-manager-config = mkHomeManagerCheck {
    name = "home-manager-config";
    extraModules = [
      {
        programs.ghidra-mcp.enable = true;
      }
    ];
  };

  home-manager-codex-config = mkHomeManagerCheck {
    name = "home-manager-codex-config";
    extraModules = [
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
    extraAssertions =
      config:
      (
        let
          expected = {
            command = "${ghidra-mcp-bridge}/bin/bridge-mcp-ghidra";
            args = [ ];
          };
          actual = config.programs.codex.settings.mcp_servers.ghidra;
        in
        assert lib.assertMsg (actual == expected)
          "home-manager-codex-config: programs.codex.settings.mcp_servers.ghidra must equal ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
        true
      );
  };
}
