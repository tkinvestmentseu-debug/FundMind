Param(
  [Parameter(Mandatory=$false)][string]$Prompt = "Answer briefly with concrete steps.",
  [Parameter(Mandatory=$false)][string]$Model  = "gpt-4o-mini"
)
$ErrorActionPreference='Stop'
$logs = "D:\FundMind\logs"
if(!(Test-Path $logs)){ New-Item -ItemType Directory -Path $logs | Out-Null }
$ts=(Get-Date).ToString('yyyyMMdd-HHmmss')

# Pobierz tekst z clipboard (VS Code: Copy as zwykle wstawia tu zaznaczenie)
try { $sel = (Get-Clipboard -Raw) } catch { $sel = "" }
$sel = if($null -ne $sel){ $sel.Trim() } else { "" }

# Zapisz do tymczasowego pliku, jeśli coś jest
$tempFile = ""
if(-not [string]::IsNullOrWhiteSpace($sel)){
  $tempFile = Join-Path $logs ("selection-" + $ts + ".txt")
  Set-Content -LiteralPath $tempFile -Value $sel -Encoding UTF8
}

# Złóż prompt
$finalPrompt = if([string]::IsNullOrWhiteSpace($sel)){
  $Prompt + " (No selection provided.)"
} else {
  $Prompt + " Use SELECTION below as primary context."
}

# Wywołaj główny CLI
$cli="D:\FundMind\tools\chatgpt-cli.ps1"
$common=@("-NoLogo","-NoProfile","-ExecutionPolicy","Bypass","-File",$cli,"-Prompt",$finalPrompt,"-Model",$Model)
if([string]::IsNullOrWhiteSpace($tempFile)){
  pwsh @common
} else {
  pwsh @($common + @("-File",$tempFile))
}
