$component = "D:\FundMind\components\AIBanner.tsx"
$ts = Get-Date -Format yyymmdd-HHmmss
Copy-Item $component "$component.bak.$ts" -Force

$content = Get-Content $component
$repl = $content.Replace('on@ress', 'onPress')
Set-Content -Path $component -Value $repl -Encoding UTf8
Write-Host "[fix-aibanner] Poprawiono fielda onPress in $component"