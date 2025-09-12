$ErrorActionPreference = "Stop"
$pkgPath = "D:\FundMind\package.json"

# read raw bytes with .NET API
[byte[]]$bytes = [System.IO.File]::ReadAllBytes($pkgPath)

if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $clean = $bytes[3..($bytes.Length-1)]
    [System.IO.File]::WriteAllBytes($pkgPath, $clean)
    Write-Output "[strip-bom-final] BOM stripped from package.json"
} else {
    Write-Output "[strip-bom-final] No BOM found in package.json"
}

# verify first bytes
[byte[]]$check = [System.IO.File]::ReadAllBytes($pkgPath)[0..2]
Write-Output ("[strip-bom-final] First 3 bytes now: " + ($check | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')
