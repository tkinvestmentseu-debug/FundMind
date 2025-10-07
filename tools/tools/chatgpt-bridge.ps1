param([string]$prompt,[switch]$auto,[string]$model="gpt-4o")
$projectRoot="D:\FundMind";$toolsDir=Join-Path $projectRoot "tools";$logsDir=Join-Path $projectRoot "logs"
if(-not(Test-Path $logsDir)){New-Item -ItemType Directory -Path $logsDir -Force|Out-Null}
$ts=Get-Date -Format "yyyyMMdd-HHmmss";$reqLog=Join-Path $logsDir ("bridge-req-"+$ts+".json");$logFile=Join-Path $logsDir ("bridge-"+$ts+".log")
$apiKeyPath=Join-Path $toolsDir "openai-key.txt";if(-not(Test-Path $apiKeyPath)){Write-Host "ERROR: $apiKeyPath not found.";exit 1}
$apiKey=(Get-Content $apiKeyPath -Raw -Encoding UTF8).Trim()
$bodyObj=@{model=$model;input=@(@{role="user";content=@(@{type="input_text";text=$prompt})})}
$body=$bodyObj|ConvertTo-Json -Depth 10 -Compress;$body|Set-Content -Path $reqLog -Encoding UTF8
try {
  $resp=Invoke-RestMethod -Uri "https://api.openai.com/v1/responses" -Method Post -Headers @{Authorization="Bearer $apiKey";"Content-Type"="application/json; charset=utf-8"} -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ErrorAction Stop
  $text=$null
  if($resp.PSObject.Properties.Name -contains "output_text"){$text=$resp.output_text}
  if(-not $text){ try{ if($resp.output.Count -gt 0 -and $resp.output[0].content.Count -gt 0){ $text=$resp.output[0].content[0].text } } catch {} }
  if(-not $text){ $text=($resp|ConvertTo-Json -Depth 12) }
  $text|Tee-Object -FilePath $logFile|Out-Host
  if($text -match '```(?:powershell|ps1|pwsh)\s*([\s\S]*?)```'){
    $code=$matches[1].Trim();$scriptPath=Join-Path $toolsDir "auto-$ts.ps1";Set-Content -Path $scriptPath -Value $code -Encoding UTF8
    if($auto){ Start-Process -FilePath "pwsh" -ArgumentList @("-NoProfile","-File",$scriptPath) -NoNewWindow -Wait }
    else{ $ans=Read-Host "Run generated code? (y/n)"; if($ans -eq "y"){ Start-Process -FilePath "pwsh" -ArgumentList @("-NoProfile","-File",$scriptPath) -NoNewWindow -Wait } }
  }
} catch {
  $msg=$_.Exception.Message;$det=$_.ErrorDetails.Message;Write-Host "API ERROR: $msg";Add-Content -Path $logFile -Value ("API ERROR: "+$msg);if($det){Write-Host "DETAILS: $det";Add-Content -Path $logFile -Value ("DETAILS: "+$det)}
}

