#!/usr/bin/env bash
set -euo pipefail

# ComfyUI Cloud MCP Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/install.sh | bash

MCP_URL="${MCP_URL:-https://cloud.comfy.org/mcp}"
# Derive validation URL from MCP_URL base (strip /mcp path, add /api/queue)
MCP_BASE="${MCP_URL%/mcp}"
VALIDATION_URL="${VALIDATION_URL:-${MCP_BASE}/api/queue}"
SKILLS_BASE_URL="https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/skills"
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

detect_cursor() {
  [[ -d "$HOME/.cursor" ]]
}

get_cursor_config_path() {
  echo "$HOME/.cursor/mcp.json"
}

detect_amp() {
  command -v amp &>/dev/null
}

# ── API key handling ────────────────────────────────────────────────────
read_api_key() {
  local key=""
  echo -en "  Paste your API key: " >&2
  read -r key < /dev/tty
  echo "$key"
}

VALIDATION_ERROR=""

validate_api_key() {
  local key="$1"
  VALIDATION_ERROR=""
  local tmpfile
  tmpfile=$(mktemp)
  local status
  status=$(curl -s -o "$tmpfile" -w "%{http_code}" -H "X-API-Key: $key" "$VALIDATION_URL" 2>/dev/null) || true
  if [[ "$status" == "401" || "$status" == "403" ]]; then
    # Try to extract the error message from the response body
    VALIDATION_ERROR=$(python3 -c "
import json, sys
try:
    d = json.load(open('$tmpfile'))
    print(d.get('message', ''))
except: pass
" 2>/dev/null) || true
    rm -f "$tmpfile"
    return 1
  fi
  rm -f "$tmpfile"
  return 0
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

# ── Configure Claude Desktop ──────────────────────────────────────────
configure_claude_desktop() {
  local api_key="$1"

  # Claude Desktop chat mode requires OAuth for remote MCP servers via
  # Settings > Connectors. OAuth support is coming soon. For now, users
  # can use Code mode within the Desktop app (configured via Claude Code).
  echo ""
  warn "Claude Desktop (chat mode): OAuth support coming soon."
  echo -e "  ${DIM}In the meantime, use ${BOLD}Code mode${RESET}${DIM} within Claude Desktop —${RESET}"
  echo -e "  ${DIM}it connects to Comfy Cloud automatically via the Claude Code config.${RESET}"
  echo ""
}

# ── Configure Cursor (JSON file) ───────────────────────────────────────
configure_cursor() {
  local api_key="$1"
  local config_path
  config_path=$(get_cursor_config_path)

  mkdir -p "$(dirname "$config_path")"

  python3 -c "
import json, os

config_path = '$config_path'
api_key = '$api_key'
mcp_url = '$MCP_URL'

config = {}
if os.path.exists(config_path):
    with open(config_path) as f:
        config = json.load(f)

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['comfyui-cloud'] = {
    'type': 'url',
    'url': mcp_url,
    'headers': {
        'X-API-Key': api_key
    }
}

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
" 2>/dev/null

  if [[ $? -eq 0 ]]; then
    success "Cursor configured ${DIM}($config_path)${RESET}"
    return 0
  else
    fail "Cursor: could not write config"
    return 1
  fi
}

# ── Configure Amp (CLI) ───────────────────────────────────────────────
configure_amp() {
  local api_key="$1"

  amp mcp remove comfyui-cloud 2>/dev/null || true

  amp mcp add \
    --transport http \
    comfyui-cloud \
    "$MCP_URL" \
    -H "X-API-Key: $api_key" 2>/dev/null

  if [[ $? -eq 0 ]]; then
    success "Amp configured"
    return 0
  else
    warn "Amp: could not configure automatically. You may need to set it up manually."
    return 1
  fi
}

# ── Configure Claude Code (CLI) ────────────────────────────────────────
configure_claude_code() {
  local api_key="$1"
  local scope="$2"

  # Remove existing from both scopes to avoid shadowing
  claude mcp remove comfyui-cloud -s user 2>/dev/null || true
  claude mcp remove comfyui-cloud -s local 2>/dev/null || true

  claude mcp add \
    --transport http \
    -s "$scope" \
    comfyui-cloud \
    "$MCP_URL" \
    -H "X-API-Key: $api_key" 2>/dev/null

  if [[ $? -eq 0 ]]; then
    success "Claude Code configured ${DIM}($scope scope)${RESET}"
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
    "comfy-help.md"
    "comfy-rickroll.md"
    "comfy-search-models.md"
    "comfy-search-nodes.md"
    "comfy-search-templates.md"
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
  local has_cursor=false
  local has_amp=false

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

  if detect_cursor; then
    has_cursor=true
    success "Cursor"
  else
    info "Cursor (not found)"
  fi

  if detect_amp; then
    has_amp=true
    success "Amp"
  else
    info "Amp (not found)"
  fi

  if ! $has_claude_code && ! $has_claude_desktop && ! $has_cursor && ! $has_amp; then
    echo ""
    fail "No supported MCP clients found."
    echo ""
    info "Install Claude Code:    https://docs.anthropic.com/en/docs/claude-code"
    info "Install Claude Desktop: https://claude.ai/download"
    info "Install Cursor:         https://cursor.com"
    echo ""
    exit 1
  fi

  # Claude Desktop chat mode doesn't support API key auth yet (OAuth coming soon).
  # If it's the only client, let the user know they need Claude Code.
  if ! $has_claude_code && ! $has_cursor && ! $has_amp && $has_claude_desktop; then
    echo ""
    warn "Claude Desktop chat mode requires OAuth (coming soon)."
    echo ""
    echo -e "  Install ${BOLD}Claude Code${RESET} to use Comfy Cloud MCP today:"
    echo -e "  ${CYAN}https://docs.anthropic.com/en/docs/claude-code${RESET}"
    echo ""
    echo -e "  ${DIM}Claude Code works as a standalone CLI and inside the Claude Desktop app.${RESET}"
    echo -e "  ${DIM}Also supported: Cursor, Amp.${RESET}"
    echo ""
    exit 0
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

  # Get API key
  echo ""
  heading "API Key"
  echo ""
  echo -e "  Get one at: ${CYAN}https://platform.comfy.org/profile/api-keys${RESET}"
  echo -e "  Click ${COMFY_YELLOW}\"New API Key\"${RESET} and copy it."
  echo ""

  local api_key=""
  local max_attempts=3

  for attempt in $(seq 1 $max_attempts); do
    api_key=$(read_api_key)

    if [[ -z "$api_key" ]]; then
      local remaining=$((max_attempts - attempt))
      if [[ $remaining -gt 0 ]]; then
        warn "No key entered. $remaining attempt(s) remaining. (Ctrl+C to quit)"
        echo ""
        continue
      fi
      fail "No key entered."
      exit 1
    fi

    if [[ "$api_key" != comfyui-* ]]; then
      warn "Key doesn't start with \"comfyui-\". Are you sure it's correct?"
      echo -en "  Continue anyway? (y/N): "
      read -r cont < /dev/tty
      if [[ "$(echo "$cont" | tr '[:upper:]' '[:lower:]')" != "y" ]]; then
        if [[ $attempt -lt $max_attempts ]]; then
          echo ""
          continue
        fi
        exit 1
      fi
    fi

    echo -e "  Validating key..."
    if validate_api_key "$api_key"; then
      success "API key is valid"
      break
    else
      local remaining=$((max_attempts - attempt))
      local err_msg="Invalid or unauthorized API key."
      if [[ -n "$VALIDATION_ERROR" ]]; then
        err_msg="$VALIDATION_ERROR"
      fi
      if [[ $remaining -gt 0 ]]; then
        fail "$err_msg $remaining attempt(s) remaining."
        echo ""
        continue
      fi
      fail "$err_msg"
      echo -e "  Check your key at ${CYAN}https://platform.comfy.org/profile/api-keys${RESET}"
      exit 1
    fi
  done

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
    configure_claude_code "$api_key" "$scope" || true
  fi

  if $has_claude_desktop; then
    info "Claude Desktop (chat mode): OAuth support coming soon. Use Code mode for now."
  fi

  if $has_cursor; then
    configure_cursor "$api_key" || true
  fi

  if $has_amp; then
    configure_amp "$api_key" || true
  fi

  # Slash commands
  local skills_installed=false
  local skill_dirs=()

  # Install slash commands for Claude Code CLI, or for Claude Desktop (which
  # includes Code mode that reads from ~/.claude/commands/)
  if $has_claude_code || $has_claude_desktop; then
    skill_dirs+=("$HOME/.claude/commands:Claude Code")
  fi

  if $has_cursor; then
    skill_dirs+=("$HOME/.cursor/commands:Cursor")
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

  # Done
  echo ""
  success "${BOLD}Install complete!${RESET} Restart your MCP clients to connect."
  echo ""
}

main "$@"
