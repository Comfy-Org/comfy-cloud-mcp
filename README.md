# Comfy Cloud MCP

Connect your AI agent to [Comfy Cloud](https://cloud.comfy.org) for image generation, model search, and workflow management — directly from Claude, Cursor, and other MCP-compatible clients.

## Install

**macOS / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/install.ps1 | iex
```

The installer will:
1. Detect your MCP clients (Claude Code, Claude Desktop)
2. Ask for your [Comfy Cloud API key](https://platform.comfy.org/profile/api-keys)
3. Configure the remote MCP server
4. Optionally install slash commands for better workflow context

No Node.js or other dependencies required.

## What you can do

Once installed, your AI agent can:

- **Generate images** — describe what you want, the agent builds and runs a ComfyUI workflow
- **Search models** — find checkpoints, LoRAs, VAEs, and controlnets across HuggingFace and CivitAI
- **Search nodes** — discover ComfyUI nodes by category, input/output type, or keyword
- **Browse templates** — find pre-built workflows for text-to-image, image-to-video, style transfer, and more
- **Manage workflows** — list, inspect, and run your saved workflows from Comfy Cloud
- **Chain outputs** — use the output of one workflow as input to another

## Slash commands

The installer can add these slash commands to Claude Code:

| Command | Description |
|---------|-------------|
| `/comfy-generate-image` | Generate images from a text description |
| `/comfy-search-models` | Search available models with formatted results |
| `/comfy-search-nodes` | Search for nodes and get wiring suggestions |
| `/comfy-search-templates` | Find pre-built workflow templates |
| `/comfy-help` | See what you can do with ComfyUI Cloud |

## Manual setup

If you prefer to configure manually:

**Claude Code:**

```bash
claude mcp add --transport http -s user \
  -H "X-API-Key: YOUR_API_KEY" \
  comfyui-cloud \
  https://cloud.comfy.org/mcp
```

**Claude Desktop** (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "comfyui-cloud": {
      "type": "url",
      "url": "https://cloud.comfy.org/mcp",
      "headers": {
        "X-API-Key": "YOUR_API_KEY"
      }
    }
  }
}
```

## Get an API key

1. Go to [platform.comfy.org/profile/api-keys](https://platform.comfy.org/profile/api-keys)
2. Click **"New API Key"**
3. Copy the key (starts with `comfyui-`)

## Links

- [Comfy Cloud](https://cloud.comfy.org)
- [Comfy Cloud Platform](https://platform.comfy.org)
