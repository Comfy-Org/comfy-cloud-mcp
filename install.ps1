# ComfyUI Cloud MCP Installer for Windows
# Usage: irm https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$MCP_URL = if ($env:MCP_URL) { $env:MCP_URL } else { "https://cloud.comfy.org/mcp" }
$VALIDATION_URL = if ($env:VALIDATION_URL) { $env:VALIDATION_URL } else { "https://cloud.comfy.org/api/queue" }
$SKILLS_BASE_URL = "https://raw.githubusercontent.com/Comfy-Org/comfy-cloud-mcp/main/skills"

# ── Colors ──────────────────────────────────────────────────────────────
$ESC = [char]27

function Write-Success($msg) { Write-Host "  $ESC[32m✓$ESC[0m $msg" }
function Write-Fail($msg)    { Write-Host "  $ESC[31m✗$ESC[0m $msg" }
function Write-Warn($msg)    { Write-Host "  $ESC[38;2;240;255;83m!$ESC[0m $msg" }
function Write-Info($msg)    { Write-Host "  $ESC[2m$msg$ESC[0m" }
function Write-Heading($msg) { Write-Host "  $ESC[36m━━ $ESC[1m$msg$ESC[0m $ESC[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$ESC[0m" }

# ── Banner ──────────────────────────────────────────────────────────────
function Show-Banner {
    $B = "$ESC[48;2;26;44;206m"
    $Y = "$ESC[48;2;26;44;206m$ESC[38;2;240;255;83m$ESC[1m"
    $R = "$ESC[0m"
    Write-Host ""
    Write-Host "  ${B}                          ${R}"
    Write-Host "  ${B}          ${Y}██████████${B}      ${R}"
    Write-Host "  ${B}        ${Y}██████████${B}        ${R}"
    Write-Host "  ${B}       ${Y}█████${B}               ${R}"
    Write-Host "  ${B}      ${Y}█████${B}                ${R}"
    Write-Host "  ${B}     ${Y}█████${B}                 ${R}"
    Write-Host "  ${B}      ${Y}█████${B}                ${R}"
    Write-Host "  ${B}      ${Y}██████████${B}           ${R}"
    Write-Host "  ${B}       ${Y}██████████${B}          ${R}"
    Write-Host "  ${B}                          ${R}"
    Write-Host ""
    Write-Host "  $ESC[1m$ESC[97mComfyUI Cloud$ESC[0m $ESC[2mMCP Server$ESC[0m"
    Write-Host "  $ESC[2minstall$ESC[0m"
    Write-Host ""
}

# ── Detect MCP clients ─────────────────────────────────────────────────
function Test-ClaudeCode {
    try { Get-Command claude -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

function Test-ClaudeDesktop {
    $configDir = Join-Path $env:APPDATA "Claude"
    return (Test-Path $configDir)
}

function Test-Amp {
    try { Get-Command amp -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

function Get-AmpConfigPath {
    if ($env:AMP_SETTINGS_FILE) { return $env:AMP_SETTINGS_FILE }
    return Join-Path $env:APPDATA "amp\settings.json"
}

# ── API key handling ────────────────────────────────────────────────────
function Read-ApiKey {
    Write-Host -NoNewline "  Paste your API key: "
    $key = ""
    while ($true) {
        $keyInfo = [Console]::ReadKey($true)
        if ($keyInfo.Key -eq "Enter") { Write-Host ""; return $key }
        if ($keyInfo.Key -eq "Backspace") {
            if ($key.Length -gt 0) {
                $key = $key.Substring(0, $key.Length - 1)
                Write-Host -NoNewline "`b `b"
            }
        } else {
            $key += $keyInfo.KeyChar
            Write-Host -NoNewline "*"
        }
    }
}

function Test-ApiKey($key) {
    try {
        $response = Invoke-WebRequest -Uri $VALIDATION_URL -Headers @{"X-API-Key" = $key} -Method Get -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 401 -or $status -eq 403) { return $false }
        # Can't reach API, let it through
        return $true
    }
}

# ── Configure Claude Code ──────────────────────────────────────────────
# Claude Desktop has no config-file route to a remote OAuth connector — it's
# added through the Connectors UI, which then runs the OAuth browser flow. We
# print those steps in the "Finish Sign-In" section; there's nothing to write.
function Install-ClaudeCode($scope) {
    # Remove existing from both scopes. Also clears any stale X-API-Key header
    # from a previous install — Claude Code treats a rejected header as a hard
    # failure and won't fall back to OAuth, so OAuth means no header at all.
    & claude mcp remove comfyui-cloud -s user 2>$null
    & claude mcp remove comfyui-cloud -s local 2>$null

    # No -H header -> Claude Code runs the MCP OAuth flow on first connect.
    & claude mcp add --transport http -s $scope comfyui-cloud $MCP_URL 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Claude Code configured $ESC[2m($scope scope, OAuth)$ESC[0m"
    } else {
        Write-Fail "Claude Code: claude mcp add failed"
    }
}

# ── Configure Amp ──────────────────────────────────────────────────────
# Amp's `mcp add` CLI auto-detects transport from the URL and has no flag
# for HTTP headers — they live in settings.json under `amp.mcpServers`.
# We write the entry directly so the X-API-Key header survives.
function Install-Amp($apiKey) {
    $configPath = Get-AmpConfigPath
    $configDir = Split-Path $configPath

    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $config = @{}
    if (Test-Path $configPath) {
        try {
            $loaded = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
            if ($null -ne $loaded) { $config = $loaded }
        } catch {
            Write-Warn "Amp: existing settings.json is not valid JSON; leaving manual setup to user"
            return
        }
    }

    if (-not $config.ContainsKey("amp.mcpServers")) {
        $config["amp.mcpServers"] = @{}
    }

    $config["amp.mcpServers"]["comfyui-cloud"] = @{
        url = $MCP_URL
        headers = @{
            "X-API-Key" = $apiKey
        }
    }

    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
    Write-Success "Amp configured $ESC[2m($configPath)$ESC[0m"
}

# ── Install slash commands ──────────────────────────────────────────────
function Install-Skills($targetDir, $clientName) {
    $skills = @(
        "comfy-generate-image.md"
        "comfy-help.md"
        "comfy-rickroll.md"
        "comfy-search-models.md"
        "comfy-search-nodes.md"
        "comfy-search-templates.md"
        "technique-combine-people.md"
    )

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $count = 0
    foreach ($skill in $skills) {
        try {
            Invoke-WebRequest -Uri "$SKILLS_BASE_URL/$skill" -OutFile (Join-Path $targetDir $skill) -UseBasicParsing -ErrorAction Stop
            $count++
        } catch {}
    }

    if ($count -gt 0) {
        Write-Success "$count slash commands installed for $clientName"
    } else {
        Write-Fail "Could not download slash commands"
    }
}

# ── Main ────────────────────────────────────────────────────────────────
function Main {
    Show-Banner

    $hasClaudeCode = Test-ClaudeCode
    $hasClaudeDesktop = Test-ClaudeDesktop
    $hasAmp = Test-Amp

    Write-Heading "Detecting Clients"
    Write-Host ""

    if ($hasClaudeCode) { Write-Success "Claude Code" }
    else { Write-Info "Claude Code (not found)" }

    if ($hasClaudeDesktop) { Write-Success "Claude Desktop" }
    else { Write-Info "Claude Desktop (not found)" }

    if ($hasAmp) { Write-Success "Amp" }
    else { Write-Info "Amp (not found)" }

    if (-not $hasClaudeCode -and -not $hasClaudeDesktop -and -not $hasAmp) {
        Write-Host ""
        Write-Fail "No supported MCP clients found."
        Write-Host ""
        Write-Info "Install Claude Code:    https://docs.anthropic.com/en/docs/claude-code"
        Write-Info "Install Claude Desktop: https://claude.ai/download"
        Write-Info "Install Amp:            https://ampcode.com"
        Write-Host ""
        exit 1
    }

    # API key is only needed for clients still on the header path (Amp).
    # Claude Code and Claude Desktop use OAuth and need no key.
    $apiKey = ""
    if ($hasAmp) {
        Write-Host ""
        Write-Heading "API Key"
        Write-Host ""
        Write-Host "  $ESC[2mAmp doesn't support OAuth yet — it needs an API key.$ESC[0m"
        Write-Host "  Get one at: $ESC[36mhttps://platform.comfy.org/profile/api-keys$ESC[0m"
        Write-Host "  Click $ESC[38;2;240;255;83m`"New API Key`"$ESC[0m and copy it."
        Write-Host ""

        $maxAttempts = 3

        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            $apiKey = Read-ApiKey

            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                $remaining = $maxAttempts - $attempt
                if ($remaining -gt 0) {
                    Write-Warn "No key entered. $remaining attempt(s) remaining. (Ctrl+C to quit)"
                    Write-Host ""
                    continue
                }
                Write-Fail "No key entered."
                exit 1
            }

            if (-not $apiKey.StartsWith("comfyui-")) {
                Write-Warn "Key doesn't start with `"comfyui-`". Are you sure it's correct?"
                $cont = Read-Host "  Continue anyway? (y/N)"
                if ($cont.ToLower() -ne "y") {
                    if ($attempt -lt $maxAttempts) { Write-Host ""; continue }
                    exit 1
                }
            }

            Write-Host "  Validating key..."
            if (Test-ApiKey $apiKey) {
                Write-Success "API key is valid"
                break
            } else {
                $remaining = $maxAttempts - $attempt
                if ($remaining -gt 0) {
                    Write-Fail "Invalid or unauthorized API key. $remaining attempt(s) remaining."
                    Write-Host ""
                    continue
                }
                Write-Fail "Invalid or unauthorized API key."
                Write-Host "  Check your key at $ESC[36mhttps://platform.comfy.org/profile/api-keys$ESC[0m"
                exit 1
            }
        }
    }

    # Configure clients
    Write-Host ""
    Write-Heading "Configuring Clients"
    Write-Host ""

    if ($hasClaudeCode) {
        Write-Host "  Install for Claude Code:"
        Write-Host "    $ESC[38;2;240;255;83m1$ESC[0m) All projects (user scope)"
        Write-Host "    $ESC[2m2$ESC[0m) This project only (local scope)"
        $scopeChoice = Read-Host "  Choice [1]"
        $scope = if ($scopeChoice -eq "2") { "local" } else { "user" }
        Install-ClaudeCode $scope
    }

    if ($hasClaudeDesktop) {
        Write-Info "Claude Desktop: added via the Connectors UI (steps below)."
    }

    if ($hasAmp) {
        Install-Amp $apiKey
    }

    # Slash commands
    $skillDirs = @()
    if ($hasClaudeCode) {
        $skillDirs += @{ Dir = (Join-Path $HOME ".claude\commands"); Name = "Claude Code" }
    }

    if ($skillDirs.Count -gt 0) {
        Write-Host ""
        Write-Heading "Slash Commands"
        Write-Host ""
        Write-Host "  These give your AI agent better context for ComfyUI workflows."
        Write-Host "  The MCP works without them, but they improve results."
        Write-Host ""
        Write-Host "    $ESC[38;2;240;255;83m/comfy-generate-image$ESC[0m $ESC[2m— Generate images from a description$ESC[0m"
        Write-Host "    $ESC[38;2;240;255;83m/comfy-search-models$ESC[0m  $ESC[2m— Search available models$ESC[0m"
        Write-Host "    $ESC[38;2;240;255;83m/comfy-search-nodes$ESC[0m   $ESC[2m— Search for nodes$ESC[0m"
        Write-Host "    $ESC[38;2;240;255;83m/comfy-search-templates$ESC[0m $ESC[2m— Find pre-built workflows$ESC[0m"
        Write-Host "    $ESC[38;2;240;255;83m/comfy-help$ESC[0m           $ESC[2m— See what you can do$ESC[0m"
        Write-Host ""
        $installChoice = Read-Host "  Install slash commands? (Y/n)"

        if ($installChoice.ToLower() -ne "n") {
            foreach ($entry in $skillDirs) {
                Install-Skills $entry.Dir $entry.Name
            }
        } else {
            Write-Info "Skipped slash commands."
        }
    }

    # Finish sign-in (OAuth clients)
    if ($hasClaudeCode -or $hasClaudeDesktop) {
        Write-Host ""
        Write-Heading "Finish Sign-In"
        Write-Host ""
        Write-Host "  Comfy Cloud uses OAuth — sign in once per client (no API key needed):"
        Write-Host ""
        if ($hasClaudeCode) {
            Write-Host "  $ESC[1mClaude Code$ESC[0m"
            Write-Host "    Run $ESC[38;2;240;255;83m/mcp$ESC[0m -> select $ESC[1mcomfyui-cloud$ESC[0m -> $ESC[1mAuthenticate$ESC[0m."
            Write-Host "    $ESC[2mYour browser opens to sign in. Tokens refresh automatically.$ESC[0m"
            Write-Host ""
        }
        if ($hasClaudeDesktop) {
            Write-Host "  $ESC[1mClaude Desktop$ESC[0m"
            Write-Host "    Settings -> Connectors -> $ESC[1mAdd custom connector$ESC[0m"
            Write-Host "    URL: $ESC[36m$MCP_URL$ESC[0m"
            Write-Host "    $ESC[2mThen click Connect and sign in.$ESC[0m"
            Write-Host ""
        }
    }

    # Done
    Write-Host ""
    Write-Success "$ESC[1mInstall complete!$ESC[0m Restart your MCP clients to connect."
    Write-Host ""
}

Main
