$ErrorActionPreference = 'Stop'
$projectRoot = 'D:\FundMind'
$logsDir = Join-Path $projectRoot 'logs'
if (!(Test-Path $logsDir)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$log = Join-Path $logsDir ('runner_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')
function Log([string]$m){ $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); $l="[$ts] $m"; Write-Host $l; Add-Content -Path $log -Value $l }
function Bkp([string]$p){ if(Test-Path $p){ $b="$p.bak."+((Get-Date).ToString("yyyyMMdd_HHmmss")); Copy-Item -LiteralPath $p -Destination $b -Force; Log "Backup: $p -> $b" } }

# 1) TileKit: Add tile + inject grid (if tools present)
$tileKit = Join-Path $projectRoot 'tools\FundMind.TileKit.ps1'
if (Test-Path $tileKit) {
  . $tileKit
  try { Log "AddTile add-transaction"; AddTile -Id 'add-transaction' -Label 'Dodaj transakcje' -Href '/addTransaction' -TestId 'tile-add-tx' } catch { Log ("AddTile failed: "+$_.Exception.Message) }
  try { Log "InjectStart"; InjectStart } catch { Log ("InjectStart failed: "+$_.Exception.Message) }
} else {
  Log "TileKit not found (tools\FundMind.TileKit.ps1). Skipping."
}

# 2) RNTL test for PremiumAiBanner
$testsDir = Join-Path $projectRoot '__tests__'
if (!(Test-Path $testsDir)) { New-Item -ItemType Directory -Force -Path $testsDir | Out-Null }
$old = Join-Path $testsDir 'PremiumAiBanner.test.tsx'
if (Test-Path $old) { Bkp $old; Remove-Item -LiteralPath $old -Force }
$new = Join-Path $testsDir 'PremiumAiBanner.rntl.test.tsx'
$T = @()
$T += '/* RNTL smoke test dla PremiumAiBanner (ASCII-only) */'
$T += 'import React from "react";'
$T += 'import { render } from "@testing-library/react-native";'
$T += 'jest.useFakeTimers();'
$T += 'import PremiumAiBanner from "../app/components/PremiumAiBanner";'
$T += ''
$T += 'test("renders PremiumAiBanner without crashing", () => {'
$T += '  const screen = render(<PremiumAiBanner disableAnimation />);'
$T += '  expect(screen.toJSON()).toBeTruthy();'
$T += '});'
Set-Content -LiteralPath $new -Value $T -Encoding UTF8
Log ("Wrote test file: " + $new)

# 3) Lint / Typecheck / Test
Push-Location $projectRoot
try { Log "npm run lint"; npm run lint --silent } catch { Log ("lint failed: "+$_.Exception.Message); throw }
try { Log "npm run typecheck"; npm run typecheck --silent } catch { Log ("typecheck failed: "+$_.Exception.Message); throw }
try { Log "npm run test"; npm run test --silent } catch { Log ("tests failed: "+$_.Exception.Message); throw } finally { Pop-Location }
Log "DONE"
Write-Host "DONE"
