# Manual MCP client configuration

This guide shows how to configure MCP-capable coding agents to launch the
packaged `bridge-mcp-ghidra` command manually. It does not require or imply an
agent-specific Nix or Home Manager integration.

The snippets follow the latest published client documentation and were last
verified on **2026-07-29**. Agent configuration formats change frequently; use
the linked client documentation as the source of truth if a snippet no longer
matches an installed version.

## How the connection works

Each client starts `bridge-mcp-ghidra` as a local
[MCP stdio](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports#stdio)
server:

```text
MCP client <-- stdio --> bridge-mcp-ghidra <-- local API --> GhidraMCP plugin
```

The Ghidra plugin's default TCP endpoint at `http://127.0.0.1:8089` is its local
HTTP API, not an MCP HTTP endpoint. Do not configure that URL as the MCP server.

Before configuring a client, confirm that the bridge is installed:

```console
command -v bridge-mcp-ghidra
bridge-mcp-ghidra --help
```

The snippets use `bridge-mcp-ghidra` so they remain portable across Nix
generations. If a client cannot find it because it starts with a restricted
`PATH`, replace the command with the absolute path printed by `command -v`.

Merge the relevant entry into an existing configuration file. Do not replace
unrelated settings or MCP servers.

## OpenCode

Run `opencode --version`, then use the configuration matching its major
version. Both versions use `~/.config/opencode/opencode.json` (or its `.jsonc`
equivalent) and represent the command and its arguments as one array.

### OpenCode 1

OpenCode 1 defines each server directly beneath `mcp` and uses `enabled` to
control whether it starts:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "ghidra": {
      "type": "local",
      "command": ["bridge-mcp-ghidra"],
      "enabled": true
    }
  }
}
```

See the [OpenCode 1 MCP documentation](https://opencode.ai/docs/mcp-servers/).

### OpenCode 2

OpenCode 2 defines servers beneath `mcp.servers`. Servers start by default, and
v2 does not accept the v1 `enabled` field:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "ghidra": {
        "type": "local",
        "command": ["bridge-mcp-ghidra"]
      }
    }
  }
}
```

See the
[OpenCode 2 MCP documentation](https://opencode.ai/v2/docs/mcp-servers).

After changing either configuration, restart OpenCode and inspect the server
with:

```console
opencode mcp list
```

## Kimi Code

Add this to `~/.kimi-code/mcp.json`, or `$KIMI_CODE_HOME/mcp.json` when
`KIMI_CODE_HOME` is set:

```json
{
  "mcpServers": {
    "ghidra": {
      "command": "bridge-mcp-ghidra",
      "args": []
    }
  }
}
```

Start a new Kimi Code session, then run `/mcp` to inspect the connection.
Kimi Code also provides `/mcp-config` for interactive configuration. See the
[Kimi Code MCP documentation](https://www.kimi.com/code/docs/en/kimi-code-cli/customization/mcp.html).

## Grok Build

Add this table to `~/.grok/config.toml`, or `$GROK_HOME/config.toml` when
`GROK_HOME` is set:

```toml
[mcp_servers.ghidra]
command = "bridge-mcp-ghidra"
args = []
```

The CLI can add the same user-level entry:

```console
grok mcp add ghidra -- bridge-mcp-ghidra
```

Restart Grok Build, then inspect and diagnose the server with:

```console
grok mcp list
grok mcp doctor ghidra
```

The TUI's `/mcps` command also shows configured servers and can refresh them
after configuration changes. See the
[Grok Build MCP documentation](https://docs.x.ai/build/features/mcp-servers).

## Codex CLI

Add this table to `~/.codex/config.toml`:

```toml
[mcp_servers.ghidra]
command = "bridge-mcp-ghidra"
args = []
```

Restart Codex, then inspect the server with:

```console
codex mcp list
```

The Codex TUI also shows active servers through `/mcp`. See the
[Codex MCP documentation](https://developers.openai.com/codex/mcp/).

The Home Manager module's `enableCodexIntegration` option generates the
equivalent configuration automatically. Use either that option or this manual
entry; defining both is unnecessary.

## oh-my-pi

Add this to `~/.omp/agent/mcp.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json",
  "mcpServers": {
    "ghidra": {
      "type": "stdio",
      "command": "bridge-mcp-ghidra",
      "args": []
    }
  }
}
```

When using `omp --profile NAME`, put the entry in
`~/.omp/profiles/NAME/agent/mcp.json` instead. Reload and test it from oh-my-pi:

```text
/mcp reload
/mcp test ghidra
```

See the
[oh-my-pi MCP configuration guide](https://github.com/can1357/oh-my-pi/blob/main/docs/mcp-config.md).

## Claude Code

Merge this user-level entry into `~/.claude.json`:

```json
{
  "mcpServers": {
    "ghidra": {
      "type": "stdio",
      "command": "bridge-mcp-ghidra",
      "args": []
    }
  }
}
```

Because Claude Code manages other state in this file, its CLI is the safer way
to add the same entry without editing JSON:

```console
claude mcp add --scope user --transport stdio ghidra -- bridge-mcp-ghidra
```

Inspect the result with `claude mcp list` or `/mcp`. See the
[Claude Code MCP documentation](https://code.claude.com/docs/en/mcp).

## Activate and verify GhidraMCP

Client configuration only starts the bridge. The Ghidra plugin must also be
running:

1. Launch the packaged Ghidra and open a program in CodeBrowser.
2. Open **File > Configure > Configure All Plugins** and enable **GhidraMCP**.
3. Select **Tools > GhidraMCP > Start MCP Server**.
4. Check the plugin endpoint:

   ```console
   curl --fail http://127.0.0.1:8089/check_connection
   ```

5. Restart or reload the MCP client and inspect its `ghidra` server.
6. Make one read-only GhidraMCP request to confirm the complete path.

The package's build and flake checks do not exercise this live application,
plugin, bridge, and client connection.
