<div align="center">

<img src="assets/logo.svg" alt="ComfyUI Cloud" width="200"/>

<h1>Comfy Cloud MCP</h1>

Connect your AI agent to [Comfy Cloud](https://cloud.comfy.org) — generate images, video, audio, and 3D, search models and nodes, and run ComfyUI workflows directly from Claude Code and Claude Desktop.

</div>

> [!NOTE]
> **Closed Beta — invite only.** Access is gated by a per-user feature flag.
> If you don't have access yet, [sign up for the waitlist](https://form.typeform.com/to/hHmvw1UH).

## Install

**macOS / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/install.ps1 | iex
```

The installer detects Claude Code and Claude Desktop and configures the remote MCP server. Both sign in with **OAuth** — a one-time browser sign-in (the installer prints the steps), no API key needed. No Node.js required.

> Support is currently scoped to Claude Code and Claude Desktop while OAuth login stabilizes; other MCP clients (Cursor, Amp, etc.) will return as their OAuth support lands.

**Requirements**
- Active **Comfy Cloud subscription** (required to submit workflows)
- Your email enabled for the **closed beta** (see note above)
- Claude Code and Claude Desktop sign in with **OAuth** — no API key needed (an [API key](#get-an-api-key) is only required for headless / CI setups with no browser)

> **Claude Desktop:** added as a custom connector — **Settings → Connectors → Add custom connector**, paste `https://cloud.comfy.org/mcp`, then click **Connect** and sign in (OAuth). The installer prints these steps after running.

## Using it

**Just ask.** The agent picks the right tools on its own — *"generate a cat astronaut in space"*, *"find SDXL checkpoints"*, *"upscale this"*.

**Slash commands** (Claude Code only — shortcuts for common tasks):

| Type | What you get |
|---|---|
| `/comfy-generate-image` | Image from a prompt |
| `/comfy-generate-video` | Video from text or an image |
| `/comfy-generate-3d` | 3D mesh (GLB/FBX/OBJ) |
| `/comfy-generate-audio` | Speech or sound effects |
| `/comfy-upscale-image` | Upscale an image |
| `/comfy-remove-background` | Remove background |
| `/comfy-search-models` | Search the model catalog |
| `/comfy-search-nodes` | Search nodes with wiring hints |
| `/comfy-search-templates` | Find pre-built workflows |
| `/technique-combine-people` | Composite multiple people into one shot |
| `/comfy-help` | What can I do? |

**Tools the agent calls** (visible inline in any client as they run — name one in a prompt to steer the agent, e.g. *"use `partner_generate` with Flux Pro"*):

| Capability | Tools |
|---|---|
| Generate via workflow | `submit_workflow`, `get_job_status`, `get_output`, `cancel_job`, `get_queue` |
| Generate via partner APIs (no Cloud GPU cost) | `partner_generate` — Flux Pro, Nano Banana, Grok, GPT-image-1, Ideogram, Seedream |
| Inputs & chaining | `upload_file`, `use_previous_output` |
| Discover | `search_models`, `search_nodes`, `search_templates`, `cql` |
| Saved workflows | `save_workflow`, `list_saved_workflows`, `get_saved_workflow`, `run_saved_workflow` |
| Feedback (beta) | `submit_feedback`, `report_session_summary` |

## Feedback

This is a closed beta — please tell us what's working.

- **In-agent:** ask the agent to call `submit_feedback` (rating + comment) or `report_session_summary` (consent-gated session summary; no prompts/file paths/PII).
- **Survey:** [links.comfy.org/cloudmcpbeta](https://links.comfy.org/cloudmcpbeta)
- **Issues:** file in this repo

Tool errors include a once-per-session pointer back to these channels so you don't have to remember them.

## Get an API key

Claude Code and Claude Desktop sign in via OAuth — no key required. You only need an API key for **headless / CI** setups where no browser is available.

1. Go to [platform.comfy.org/profile/api-keys](https://platform.comfy.org/profile/api-keys)
2. Click **"New API Key"** and copy it (starts with `comfyui-`)

To wire up Claude Code manually with a key (e.g. a server with no browser):

```bash
claude mcp add --transport http comfyui-cloud https://cloud.comfy.org/mcp -H "X-API-Key: comfyui-…"
```

## Links

- [Comfy Cloud](https://cloud.comfy.org) · [Platform](https://platform.comfy.org) · [Docs](https://docs.comfy.org/development/cloud/mcp-server)
