param()
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path (Join-Path $projectRoot "logs") "step-01-run-$ts.log"

function Log($m){ $l="[step-01] $m"; Write-Host $l; Add-Content -Path $logFile -Value $l }

if (-not (Test-Path $projectRoot)) { throw "Project root not found: $projectRoot" }

# Backups of key files if exist
$backupTargets = @(
  "package.json",
  "app\_layout.tsx",
  "app\(tabs)\_layout.tsx",
  "app.config.js",
  "app.json"
) | ForEach-Object { Join-Path $projectRoot $_ }

foreach ($p in $backupTargets) {
  if (Test-Path $p) {
    $bk = "$p.bak.$ts"
    Copy-Item $p $bk -Force
    Log "Backup: $p -> $bk"
  }
}

# Ensure package.json exists
$pkg = Join-Path $projectRoot "package.json"
if (-not (Test-Path $pkg)) { throw "package.json not found at $pkg" }

# Read package.json
$pkgJson = Get-Content -Raw -Path $pkg | ConvertFrom-Json

function HasDep($name){
  return ($pkgJson.dependencies.PSObject.Properties.Name -contains $name) -or
         ($pkgJson.devDependencies.PSObject.Properties.Name -contains $name)
}

$needExpoLinGrad = -not (HasDep "expo-linear-gradient")
$needRNSVG       = -not (HasDep "react-native-svg")
$needLucide      = -not (HasDep "lucide-react-native")

if ($needExpoLinGrad -or $needRNSVG) {
  Log "Installing managed deps via expo install..."
  Push-Location $projectRoot
  npx expo install @(($needExpoLinGrad) ? "expo-linear-gradient" : $null) @(($needRNSVG) ? "react-native-svg" : $null) | Write-Output | Tee-Object -FilePath $logFile
  Pop-Location
} else {
  Log "Managed deps already present."
}

if ($needLucide) {
  Log "Installing lucide-react-native..."
  Push-Location $projectRoot
  npm i -E lucide-react-native@latest | Write-Output | Tee-Object -FilePath $logFile
  Pop-Location
} else {
  Log "lucide-react-native already present."
}

Log "Step 01 done."
