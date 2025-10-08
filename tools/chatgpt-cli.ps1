Param(
  [Parameter(Mandatory=$false)][string]$Prompt = "Explain this file briefly and propose concrete fixes.",
  [Parameter(Mandatory=$false)][string]$File   = "",
  [Parameter(Mandatory=$false)][string]$Model  = "gpt-4o-mini",
  [Parameter(Mandatory=$false)][string]$ApiBase = "https://api.openai.com/v1"
)

$ErrorActionPreference = "Stop"

function Get-OpenAIKey {
  if ($env:OPENAI_API_KEY_FILE -and (Test-Path $env:OPENAI_API_KEY_FILE)) {
    return (Get-Content -LiteralPath $env:OPENAI_API_KEY_FILE -Raw).Trim()
  }
  if ($env:OPENAI_API_KEY) { return $env:OPENAI_API_KEY.Trim() }
  throw "Missing OPENAI_API_KEY_FILE or OPENAI_API_KEY"
}

function Read-FileSafe([string]$p, [int]$maxChars = 60000){
  if ([string]::IsNullOrWhiteSpace($p) -or -not (Test-Path $p)) { return "" }
  $raw = Get-Content -LiteralPath $p -Raw
  if ($raw.Length -gt $maxChars) { return $raw.Substring(0, $maxChars) }
  return $raw
}

$NL = [Environment]::NewLine

$system = @"
You are a senior RN/Expo engineer and DevOps assistant.
Project: FundMind (Expo SDK ~50, expo-router ~3, React 18.2.0, RN 0.73.6).
Hard rules: PowerShell 7 only; ASCII-only scripts; UTF-8 no BOM; no NavigationContainer (use expo-router);
configs at repo root; avoid route duplicates; idempotent scripts; commit only after lint+typecheck+tests.
When suggesting code, return minimal diffs and full file blocks only when necessary. Be precise and production-focused.
"@

$key    = Get-OpenAIKey
$logs   = "D:\FundMind\logs"
if(-not (Test-Path $logs)){ New-Item -ItemType Directory -Path $logs | Out-Null }
$ts     = (Get-Date).ToString("yyyyMMdd-HHmmss")
$rawOut = Join-Path $logs "chatgpt-$ts.json"
$mdOut  = Join-Path $logs "chatgpt-$ts.md"
$lastMd = Join-Path $logs "last-chatgpt.md"

$fileBlob = Read-FileSafe -p $File

if ([string]::IsNullOrWhiteSpace($fileBlob)) {
  $userMsg = $Prompt
} else {
  $userMsg = "QUESTION:" + $NL + $Prompt + $NL + $NL +
             "FILE (" + $File + "):" + $NL +
             "<<<FILE_START>>>" + $NL +
             $fileBlob + $NL +
             "<<<FILE_END>>>"
}

$bodyObj = @{
  model = $Model
  messages = @(
    @{ role = "system"; content = $system },
    @{ role = "user";   content = $userMsg }
  )
  temperature = 0.2
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 10
$headers = @{
  "Authorization" = "Bearer " + $key
  "Content-Type"  = "application/json"
}

try {
  $resp = Invoke-RestMethod -Method Post -Uri (($ApiBase.TrimEnd('/')) + "/chat/completions") -Headers $headers -Body $bodyJson -TimeoutSec 300
} catch {
  $_ | Out-String | Set-Content -Path (Join-Path $logs ("chatgpt-error-" + $ts + ".txt")) -Encoding UTF8
  throw
}

$content = ""
try { $content = $resp.choices[0].message.content } catch {}

($resp | ConvertTo-Json -Depth 12) | Set-Content -Path $rawOut -Encoding UTF8
("# Prompt", "", $Prompt, "", "# File", "", $File, "", "# Answer", "", $content) -join "`r`n" | Set-Content -Path $mdOut -Encoding UTF8
Copy-Item -LiteralPath $mdOut -Destination $lastMd -Force

Write-Host ""
Write-Host "=== ChatGPT (" $Model ") ==="
Write-Output $content
