<div align="center">

<img src="assets/logo.svg" alt="ComfyUI Cloud" width="200"/>

<h1>Comfy Cloud MCP</h1>

Connect your AI agent to [Comfy Cloud](https://cloud.comfy.org) — generate images, video, audio, and 3D, search models and nodes, and run ComfyUI workflows directly from Claude, Cursor, Amp, and other MCP-compatible clients.

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

The installer detects your MCP client (Claude Code, Cursor, Amp), asks for your [Comfy API key](https://platform.comfy.org/profile/api-keys), and configures the remote MCP server. No Node.js required.

**Requirements**
- Active **Comfy Cloud subscription** (required to submit workflows)
- **Comfy API key** (starts with `comfyui-`)
- Your email enabled for the **closed beta** (see note above)

> **Claude Desktop chat mode** needs OAuth, coming soon. Use **Code mode** in the meantime — it picks up the Claude Code config automatically.

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

## Links

- [Comfy Cloud](https://cloud.comfy.org) · [Platform](https://platform.comfy.org) · [Docs](https://docs.comfy.org/development/cloud/mcp-server)
