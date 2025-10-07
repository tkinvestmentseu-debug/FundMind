$component = "D:\FundMind\components\AIBanner.tsx"
$ts = Get-Date -Format yyymmdd-HHmmss
Copy-Item $component "$component.bak.$ts" -Force

$lines = Get-Content $component
$with = @()
$foundView = $false
foreach ($l in $lines) {
    if ($l.Trim() -cmatch ('^ *View ')) {
        $with += $l.Replace("Vew","<View")
        $foundView = $true
    } else { $with += $l }
}
if (-not $with.Contains("/View>") -and $foundView)  { $with += "  </View>" }
Set-Content -Path $component -Value $with -Encoding UTF8
Write-Host "[fix-aibanner] Poprawiono View in $component"