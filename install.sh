#!/usr/bin/env bash
set -euo pipefail

# ComfyUI Cloud MCP Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/install.sh | bash

MCP_URL="${MCP_URL:-https://cloud.comfy.org/mcp}"
SKILLS_BASE_URL="${SKILLS_BASE_URL:-https://raw.githubusercontent.com/Comfy-Org/comfy-skills/main/skills}"
REPO_URL="https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main"

# ── Colors ──────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
WHITE="\033[97m"
GREEN="\033[32m"
RED="\033[31m"
CYAN="\033[36m"
COMFY_YELLOW="\033[38;2;240;255;83m"
COMFY_BLUE_BG="\033[48;2;26;44;206m"

success() { echo -e "  ${GREEN}✓${RESET} $1"; }
fail()    { echo -e "  ${RED}✗${RESET} $1"; }
warn()    { echo -e "  ${COMFY_YELLOW}!${RESET} $1"; }
info()    { echo -e "  ${DIM}$1${RESET}"; }
heading() { echo -e "  ${CYAN}━━ ${BOLD}$1${RESET} ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

# ── Banner ──────────────────────────────────────────────────────────────
print_banner() {
  local B="${COMFY_BLUE_BG}"
  local Y="${COMFY_BLUE_BG}${COMFY_YELLOW}${BOLD}"
  local R="${RESET}"
  echo ""
  echo -e "  ${B}                          ${R}"
  echo -e "  ${B}          ${Y}██████████${B}      ${R}"
  echo -e "  ${B}        ${Y}██████████${B}        ${R}"
  echo -e "  ${B}       ${Y}█████${B}               ${R}"
  echo -e "  ${B}      ${Y}█████${B}                ${R}"
  echo -e "  ${B}     ${Y}█████${B}                 ${R}"
  echo -e "  ${B}      ${Y}█████${B}                ${R}"
  echo -e "  ${B}      ${Y}██████████${B}           ${R}"
  echo -e "  ${B}       ${Y}██████████${B}          ${R}"
  echo -e "  ${B}                          ${R}"
  echo ""
  echo -e "  ${BOLD}${WHITE}ComfyUI Cloud${RESET} ${DIM}MCP Server${RESET}"
  echo -e "  ${DIM}install${RESET}"
  echo ""
}

# ── Detect MCP clients ─────────────────────────────────────────────────
detect_claude_code() {
  command -v claude &>/dev/null
}

detect_claude_desktop() {
  local config_path=""
  case "$(uname -s)" in
    Darwin) config_path="$HOME/Library/Application Support/Claude/claude_desktop_config.json" ;;
    Linux)  config_path="$HOME/.config/Claude/claude_desktop_config.json" ;;
    *)      return 1 ;;
  esac
  # Desktop is available if the config dir exists
  [[ -d "$(dirname "$config_path")" ]]
}

get_claude_desktop_config_path() {
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ;;
    Linux)  echo "$HOME/.config/Claude/claude_desktop_config.json" ;;
  esac
}

# ── Check for existing installation ────────────────────────────────────
check_existing() {
  local found=false
  local existing_key=""

  # Check Claude Code
  if detect_claude_code; then
    if claude mcp list 2>/dev/null | grep -q "comfyui-cloud"; then
      found=true
      # Try to extract API key
      local detail
      detail=$(claude mcp get comfyui-cloud 2>/dev/null) || true
      existing_key=$(echo "$detail" | grep -o 'COMFY_API_KEY=[^ ]*' | cut -d= -f2) || true
    fi
  fi

  # Check Claude Desktop
  local desktop_config
  desktop_config=$(get_claude_desktop_config_path)
  if [[ -n "$desktop_config" && -f "$desktop_config" ]]; then
    if grep -q '"comfyui-cloud"' "$desktop_config" 2>/dev/null; then
      found=true
      if [[ -z "$existing_key" ]]; then
        existing_key=$(python3 -c "
import json, sys
try:
    d = json.load(open('$desktop_config'))
    srv = d.get('mcpServers', {}).get('comfyui-cloud', {})
    key = srv.get('env', {}).get('COMFY_API_KEY', '') or srv.get('headers', {}).get('X-API-Key', '')
    print(key)
except: pass
" 2>/dev/null) || true
      fi
    fi
  fi

  if $found; then
    echo "$existing_key"
    return 0
  fi
  return 1
}

# ── Configure Claude Code (CLI) ────────────────────────────────────────
configure_claude_code() {
  local scope="$1"

  # Remove existing from both scopes to avoid shadowing. This also clears any
  # stale X-API-Key header from a previous install — Claude Code treats a
  # rejected header as a hard failure and will NOT fall back to OAuth, so the
  # OAuth path requires genuinely no header.
  claude mcp remove comfyui-cloud -s user &>/dev/null || true
  claude mcp remove comfyui-cloud -s local &>/dev/null || true

  # No -H header → Claude Code runs the MCP OAuth flow on first connect.
  claude mcp add \
    --transport http \
    -s "$scope" \
    comfyui-cloud \
    "$MCP_URL" &>/dev/null

  if [[ $? -eq 0 ]]; then
    success "Claude Code configured ${DIM}($scope scope, OAuth)${RESET}"
    return 0
  else
    fail "Claude Code: claude mcp add failed"
    return 1
  fi
}

# ── Install slash commands ──────────────────────────────────────────────
install_skills() {
  local target_dir="$1"
  local client_name="$2"

  local skills=(
    "comfy-generate-image.md"
    "comfy-generate-video.md"
    "comfy-generate-audio.md"
    "comfy-generate-3d.md"
    "comfy-remove-background.md"
    "comfy-upscale-image.md"
    "comfy-search-models.md"
    "comfy-search-nodes.md"
    "comfy-search-templates.md"
    "comfy-help.md"
    "comfy-rickroll.md"
    "technique-combine-people.md"
  )

  mkdir -p "$target_dir"
  local count=0
  for skill in "${skills[@]}"; do
    if curl -fsSL "$SKILLS_BASE_URL/$skill" -o "$target_dir/$skill" 2>/dev/null; then
      count=$((count + 1))
    fi
  done

  if [[ $count -gt 0 ]]; then
    success "$count slash commands installed for $client_name"
  else
    fail "Could not download slash commands"
  fi
}

# ── Main ────────────────────────────────────────────────────────────────
main() {
  print_banner

  # Detect available clients
  local has_claude_code=false
  local has_claude_desktop=false

  heading "Detecting Clients"
  echo ""

  if detect_claude_code; then
    has_claude_code=true
    success "Claude Code"
  else
    info "Claude Code (not found)"
  fi

  if detect_claude_desktop; then
    has_claude_desktop=true
    success "Claude Desktop"
  else
    info "Claude Desktop (not found)"
  fi

  if ! $has_claude_code && ! $has_claude_desktop; then
    echo ""
    fail "No supported MCP clients found."
    echo ""
    info "Install Claude Code:    https://docs.anthropic.com/en/docs/claude-code"
    info "Install Claude Desktop: https://claude.ai/download"
    echo ""
    exit 1
  fi

  # Check for existing installation
  echo ""
  echo -en "  ${DIM}Checking for existing config...${RESET}"
  local existing_key=""
  if existing_key=$(check_existing); then
    echo -e "\r\033[K"
    warn "comfyui-cloud is already configured."
    echo ""
    echo -en "  Reinstall? (y/N): "
    read -r reinstall < /dev/tty
    if [[ "$(echo "$reinstall" | tr '[:upper:]' '[:lower:]')" != "y" ]]; then
      info "Exiting."
      exit 0
    fi
  else
    echo -e "\r\033[K"
  fi

  # Configure clients
  echo ""
  heading "Configuring Clients"
  echo ""

  if $has_claude_code; then
    # Ask scope
    echo -e "  Install for Claude Code:"
    echo -e "    ${COMFY_YELLOW}1${RESET}) All projects (user scope)"
    echo -e "    ${DIM}2${RESET}) This project only (local scope)"
    echo -en "  Choice [1]: "
    read -r scope_choice < /dev/tty
    local scope="user"
    [[ "$scope_choice" == "2" ]] && scope="local"
    configure_claude_code "$scope" || true
  fi

  if $has_claude_desktop; then
    info "Claude Desktop: added via the Connectors UI (steps below)."
  fi

  # Slash commands
  local skills_installed=false
  local skill_dirs=()

  # Install slash commands for Claude Code CLI, or for Claude Desktop (which
  # includes Code mode that reads from ~/.claude/commands/)
  if $has_claude_code || $has_claude_desktop; then
    skill_dirs+=("$HOME/.claude/commands:Claude Code")
  fi

  if [[ ${#skill_dirs[@]} -gt 0 ]]; then
    echo ""
    heading "Slash Commands"
    echo ""
    echo -e "  These give your AI agent better context for ComfyUI workflows."
    echo -e "  The MCP works without them, but they improve results."
    echo ""
    echo -e "    ${COMFY_YELLOW}/comfy-generate-image${RESET} ${DIM}— Generate images from a description${RESET}"
    echo -e "    ${COMFY_YELLOW}/comfy-search-models${RESET}  ${DIM}— Search available models${RESET}"
    echo -e "    ${COMFY_YELLOW}/comfy-search-nodes${RESET}   ${DIM}— Search for nodes${RESET}"
    echo -e "    ${COMFY_YELLOW}/comfy-search-templates${RESET} ${DIM}— Find pre-built workflows${RESET}"
    echo -e "    ${COMFY_YELLOW}/comfy-help${RESET}           ${DIM}— See what you can do${RESET}"
    echo ""
    echo -en "  Install slash commands? (Y/n): "
    read -r install_skills_choice < /dev/tty

    if [[ "$(echo "$install_skills_choice" | tr '[:upper:]' '[:lower:]')" != "n" ]]; then
      skills_installed=true
      for entry in "${skill_dirs[@]}"; do
        IFS=: read -r dir name <<< "$entry"
        install_skills "$dir" "$name"
      done
    else
      info "Skipped slash commands."
    fi
  fi

  # Finish sign-in (OAuth clients)
  if $has_claude_code || $has_claude_desktop; then
    echo ""
    heading "Finish Sign-In"
    echo ""
    echo -e "  Comfy Cloud uses OAuth — sign in once per client (no API key needed):"
    echo ""
    if $has_claude_code; then
      echo -e "  ${BOLD}Claude Code${RESET}"
      echo -e "    Run ${COMFY_YELLOW}/mcp${RESET} → select ${BOLD}comfyui-cloud${RESET} → ${BOLD}Authenticate${RESET}."
      echo -e "    ${DIM}Your browser opens to sign in. Tokens refresh automatically.${RESET}"
      echo ""
    fi
    if $has_claude_desktop; then
      echo -e "  ${BOLD}Claude Desktop${RESET}"
      echo -e "    Settings → Connectors → ${BOLD}Add custom connector${RESET}"
      echo -e "    URL: ${CYAN}${MCP_URL}${RESET}"
      echo -e "    ${DIM}Then click Connect and sign in.${RESET}"
      echo ""
    fi
  fi

  # Done
  echo ""
  success "${BOLD}Install complete!${RESET} Restart your MCP clients to connect."
  echo ""
}

main "$@"
