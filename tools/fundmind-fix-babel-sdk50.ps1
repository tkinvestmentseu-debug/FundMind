# fundmind-fix-babel-sdk50.ps1 (Anti-Error #46)

$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"

function Log-Info($m){ $t=Get-Date -Format s; Write-Host "[FixBabel50] $m"; "$t [Info] $m" | Out-File "$logsDir\update.log" -Encoding UTF8 -Append }

try {
  $babelFile = Join-Path $projectRoot "babel.config.js"
  if (!(Test-Path $babelFile)) { throw "babel.config.js not found" }

  $fixed = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
  Set-Content -Path $babelFile -Encoding UTF8 -Value $fixed
  Log-Info "babel.config.js replaced with SDK50-safe config (no expo-router/babel)"

  # Restart Metro with --clear to ensure cache invalidation
  Log-Info "Run Metro clear recommended: npx expo start --clear"
}
catch {
  Write-Host "[FixBabel50-Error] $_"
  exit 1
}
