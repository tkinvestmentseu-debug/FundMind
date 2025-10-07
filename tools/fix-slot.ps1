$dlayout = "D:\FundMind\app\_layout.tsx"
		$ts = Get-Date -Format yyyymmdd-HHmmss

Copy-Item $dlayout "$dlayout.bak.$ts" -Force



$file = Get-Content $dlayout
$found = $false
$clean = @()

foreach ($line in $file) {
    if ($line.Contains("Slot") -and $line.Contains("expo-router")) {
        if (-not $found) {
            $clean += $line
            $found = $true
        } else {
            Write-Host "[fix-slot] Removed duplicat: $line"
        }
    }
    else {
        $clean += $line
    }
}

Set-Content -Path $dlayout -Value $clean -Encoding UTF8
Write-Host "[fix-slot] Finished ochistanianie $dlayout"
