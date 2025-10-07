# fix-bridge-body2.ps1
# Naprawa body w chatgpt-bridge.ps1 – poprawny JSON z dodatkowymi polami

\D:\FundMind = "D:\FundMind"
\D:\FundMind\tools = Join-Path \D:\FundMind "tools"
\D:\FundMind\tools\chatgpt-bridge.ps1 = Join-Path \D:\FundMind\tools "chatgpt-bridge.ps1"

if (-Not (Test-Path \D:\FundMind\tools\chatgpt-bridge.ps1)) {
    Write-Host "ERROR: \D:\FundMind\tools\chatgpt-bridge.ps1 not found."
    exit 1
}

# Backup
\20250914-093452 = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item \D:\FundMind\tools\chatgpt-bridge.ps1 "\D:\FundMind\tools\chatgpt-bridge.ps1.bak.\20250914-093452" -Force
Write-Host "Backup saved to \D:\FundMind\tools\chatgpt-bridge.ps1.bak.\20250914-093452"

# Replace body building section
(Get-Content \D:\FundMind\tools\chatgpt-bridge.ps1 -Raw -Encoding UTF8) 
    -replace '(?s)\System.Collections.Hashtable = .*?\{"model":"gpt-4o","messages":[{"content":"Hello, are you alive?","role":"user"}]} = .*?\| ConvertTo-Json.*?\n', @'
\System.Collections.Hashtable = @(
  @{ role = "user"; content = "\" }
)

\ = @{
  model       = \gpt-4o
  messages    = \System.Collections.Hashtable
  temperature = 0.7
  max_tokens  = 512
}

# Build clean JSON
\{"model":"gpt-4o","messages":[{"content":"Hello, are you alive?","role":"user"}]} = \ | ConvertTo-Json -Depth 10
'@ |
Set-Content \D:\FundMind\tools\chatgpt-bridge.ps1 -Encoding UTF8

Write-Host "Patched \D:\FundMind\tools\chatgpt-bridge.ps1 with clean JSON body"
