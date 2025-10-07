param()
$ErrorActionPreference = "Stop"

$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$ts = Get-Date -Format "yyyymmdd-HHmmss"
$logFile = Join-Path $logDir "step-03-run-$ts.log"

function Log($m){ $l = "[step-03] $m"; Write-Host $l; Add-Content -Path $logFile -Value $l }


$rootLayout = Join-Path $projectRoot "app_layout.tsx"
$tabsLayout = Join-Path $projectRoot "app\\tabs)\__layout.tsx"
$target = $null

if (Test-Path $rootLayout) { $target = $rootLayout; Log "Using app/_layout.tsx" }
elseif (Test-Path $tabsLayout) { $target = $tabsLayout; Log "Using app/(tabs)/_layout.tsx" }
else { throw "No layout file found" }

Copy-Item $target "$(target).bak.$ts" -Force
Log "Backup created: $target.bak.$ts"


$src = Get-Content -Raw -Path $target
if ($src -notmatch "import { View } from 'react-native'") { $src = "import { View } from 'react-native'; `n" + $src; Log "Inserted import { View }" }
if ($src -notmatch "import AIBanner") { $src = "import AIBanner from '../components/AIBanner'; `n" + $src; Log "Inserted import AIBanner" }
if ($src -notmatch "import { Slot } from 'expo-router'") { $src = "import { Slot } from 'expo-router'; `n" + $src; Log "Inserted import Slot" }


$pattern = "return\s*(([\\s\\S]*]*);"
@evaluator = {
  param([System.Text.RegularExpressions.Match]$m)
  $nll = $m.Groups1[1].Value
  $before = "return (" + $nll + "  <View style={ flex: 1 }>" + $nll
  $middle = "    "
  $after = "      <View pointerEvents='box-none' style={ position: 'absolute', left: 0, right: 0, bottom: 72 }}>\n            <AIBanner />\n          </View>\n  </View>"
  return $before + $middle + $after
}

$dst = [System.Text.RegularExpressions.Regex]::Replace($src, $pattern, $evaluator, 1, [System.Text.RegularExpressions.Options]::Singleline)
Set-Content -Path $target -Value $dst -Encoding UTF8
Log "Layout updated with AIBanner."
Log "Step 03 done."
