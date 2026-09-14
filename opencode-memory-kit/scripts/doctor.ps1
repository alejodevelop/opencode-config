param(
    [Parameter(Position = 0)]
    [string]$Target = ".",
    [string]$ConfigDir
)

$ErrorActionPreference = "Stop"
$script:Failures = 0

function Write-Result {
    param([string]$Level, [string]$Message)
    Write-Output "$Level $Message"
    if ($Level -ceq "FAIL") { $script:Failures++ }
}

if (-not $PSBoundParameters.ContainsKey("ConfigDir")) {
    $ConfigDir = if ($env:OPENCODE_CONFIG_DIR) { $env:OPENCODE_CONFIG_DIR } else { Join-Path $HOME ".config\opencode" }
}

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Result FAIL "target directory missing: $Target"
    exit 1
}
if ([string]::IsNullOrWhiteSpace($ConfigDir)) {
    Write-Result FAIL "config directory is empty"
    exit 1
}

$root = (Resolve-Path -LiteralPath $Target).Path
$memory = Join-Path $root "docs\ai-memory"
$required = @("INDEX.md", "product-vision.md", "decisions.md", "troubleshooting.md", "features\README.md")

if (Test-Path -LiteralPath $memory -PathType Container) {
    Write-Result PASS "docs/ai-memory exists"
} else {
    Write-Result FAIL "docs/ai-memory directory missing"
}
foreach ($relative in $required) {
    $path = Join-Path $memory $relative
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Write-Result PASS "docs/ai-memory/$($relative.Replace('\', '/')) exists"
    } else {
        Write-Result FAIL "docs/ai-memory/$($relative.Replace('\', '/')) missing"
    }
}

$agentsPath = Join-Path $root "AGENTS.md"
$start = "<!-- opencode-memory-kit:start -->"
$end = "<!-- opencode-memory-kit:end -->"
if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
    Write-Result FAIL "AGENTS.md missing"
} else {
    $agents = [IO.File]::ReadAllText($agentsPath)
    $startCount = [regex]::Matches($agents, [regex]::Escape($start)).Count
    $endCount = [regex]::Matches($agents, [regex]::Escape($end)).Count
    $startLines = [regex]::Matches($agents, "(?m)^$([regex]::Escape($start))`r?$")
    $endLines = [regex]::Matches($agents, "(?m)^$([regex]::Escape($end))`r?$")
    if ($startCount -eq 1 -and $endCount -eq 1 -and $startLines.Count -eq 1 -and $endLines.Count -eq 1 -and $startLines[0].Index -lt $endLines[0].Index) {
        Write-Result PASS "AGENTS.md markers valid"
    } else {
        Write-Result FAIL "AGENTS.md requires exactly one ordered pair of exclusive marker lines"
    }
}

foreach ($name in @("sync-memory", "remember-feature", "recall-feature", "review-memory")) {
    $path = Join-Path $ConfigDir "commands\$name.md"
    if (Test-Path -LiteralPath $path -PathType Leaf) { Write-Result PASS "global command $name exists" } else { Write-Result FAIL "global command $name missing" }
}
foreach ($name in @("memory-curator", "memory-recall")) {
    $path = Join-Path $ConfigDir "agents\$name.md"
    if (Test-Path -LiteralPath $path -PathType Leaf) { Write-Result PASS "global agent $name exists" } else { Write-Result FAIL "global agent $name missing" }
}

$indexPath = Join-Path $memory "INDEX.md"
$indexed = @{}
if (Test-Path -LiteralPath $indexPath -PathType Leaf) {
    $index = [IO.File]::ReadAllText($indexPath)
    foreach ($match in [regex]::Matches($index, '(?<![A-Za-z0-9_.-])features/([A-Za-z0-9][A-Za-z0-9._-]*\.md)')) {
        $name = $match.Groups[1].Value
        if ($name -cne "README.md") { $indexed[$name] = $true }
    }
    foreach ($name in $indexed.Keys) {
        if (Test-Path -LiteralPath (Join-Path $memory "features\$name") -PathType Leaf) { Write-Result PASS "indexed feature $name exists" } else { Write-Result FAIL "indexed feature $name missing" }
    }
}

$features = Join-Path $memory "features"
if (Test-Path -LiteralPath $features -PathType Container) {
    Get-ChildItem -LiteralPath $features -File -Filter "*.md" | Where-Object { $_.Name -cne "README.md" } | ForEach-Object {
        if (-not $indexed.ContainsKey($_.Name)) { Write-Result FAIL "orphan feature note $($_.Name)" }
        $lineCount = ([IO.File]::ReadAllLines($_.FullName)).Count
        if ($lineCount -gt 50 -or $_.Length -gt 8192) { Write-Result WARN "feature note $($_.Name) is large ($lineCount lines, $($_.Length) bytes)" }
    }
}

if ($script:Failures -eq 0) { Write-Result PASS "doctor completed without failures" }
exit $(if ($script:Failures -gt 0) { 1 } else { 0 })
