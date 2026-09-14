param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)
$ErrorActionPreference = "Stop"
$failures = 0
function Fail([string]$m) { Write-Output "FAIL $m"; $script:failures++ }
function Pass([string]$m) { Write-Output "PASS $m" }

$tracked = git -C $Root ls-files
if (-not $tracked) { Fail "no tracked files"; exit 1 }

$bannedNames = @('auth.json','account.json','credentials.json','install-manifest.tsv','.agent-skills-manifest.json','.env','node_modules','bun.lock','package-lock.json','*.db','*.sqlite','*.wal','*.shm','mcp-auth')
foreach ($f in $tracked) {
    $base = Split-Path -Leaf $f
    foreach ($b in $bannedNames) {
        if ($base -like $b -or $f -like "*node_modules*" -or $f -like "*mcp-auth*" -or $f -like "*secrets/*") {
            Fail "banned artifact tracked: $f"
        }
    }
}

# Obvious literal credentials; placeholders {env:...} explicitly allowed.
# .env.example lists variable names with empty values by design: skip it here.
$patterns = @(
    'ctx7sk-[A-Za-z0-9-]{8,}',
    'sk-[A-Za-z0-9]{16,}',
    'AQ\.Ab8[A-Za-z0-9_\-]{8,}',
    'ghp_[A-Za-z0-9]{8,}',
    'github_pat_[A-Za-z0-9_]{8,}',
    'xox[bpas]-[A-Za-z0-9-]{8,}',
    '(?i)api[_-]?key[ \t]*[:=][ \t]*["'']?[A-Za-z0-9_\-]{12,}["'']?',
    '(?i)password[ \t]*[:=][ \t]*["'']?.{4,}["'']?',
    'Bearer[ \t]+[A-Za-z0-9_\-\.~\+/]{8,}={0,2}'
)
foreach ($f in $tracked) {
    $p = Join-Path $Root $f
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { continue }
    $text = [IO.File]::ReadAllText($p)
    $stripped = [regex]::Replace($text, '\{env:[A-Za-z_][A-Za-z0-9_]*\}', '')
    foreach ($pat in $patterns) {
        $m = [regex]::Matches($stripped, $pat)
        foreach ($hit in $m) {
            # Ignore self-referential pattern doc inside this check script (the Bearer line above).
            if ($f -eq 'scripts/check-portable.ps1' -and $pat.StartsWith('Bearer')) { continue }
            Fail "possible literal credential in $f (pattern: $pat)"
            break
        }
    }
}

# Absolute user-specific paths (allow OPENCODE_CONFIG examples pointing at <checkout>).
foreach ($f in $tracked) {
    if ($f -like '*.ps1' -and $f -eq 'scripts/check-portable.ps1') { continue }
    $p = Join-Path $Root $f
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { continue }
    $text = [IO.File]::ReadAllText($p)
    if ($text -match 'C:\\Users\\Alejandro|/home/alejandro|C:/Users/Alejandro') { Fail "user-absolute path in $f" }
}

# opencode.json must parse and contain only {env:...} credential references.
$cfg = Join-Path $Root 'opencode.json'
try { $json = Get-Content -LiteralPath $cfg -Raw | ConvertFrom-Json } catch { Fail "opencode.json invalid JSON"; exit 1 }
$raw = [IO.File]::ReadAllText($cfg)
if ($raw -match '\{env:[A-Za-z_][A-Za-z0-9_]*\}') { Pass "env placeholders present" } else { Fail "no {env:...} placeholders in opencode.json" }

if ($script:failures -eq 0) { Pass "portable check passed"; exit 0 } else { exit 1 }
