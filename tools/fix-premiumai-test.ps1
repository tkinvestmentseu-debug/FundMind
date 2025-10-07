param([string]$projectRoot = "D:\FundMind")
$ErrorActionPreference = "Stop"
function W($p,[string]$c){ $d=Split-Path -Parent $p; if($d -and !(Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null }; Set-Content -LiteralPath $p -Value $c -Encoding UTF8 }
$testPath = Join-Path $projectRoot "__tests__\PremiumAiBanner.test.tsx"
if(!(Test-Path -LiteralPath $testPath)){ throw "Brak pliku testu: $testPath" }
$lines = @(
"import React from 'react';",
"import { render, waitFor } from '@testing-library/react-native';",
"import PremiumAiBanner from '../app/_components/PremiumAiBanner';",
"",
"test('renders PremiumAiBanner', async () => {",
"  jest.useFakeTimers();",
"  const screen = render(<PremiumAiBanner />);",
"  // spuść kolejkę animacji/timerów uruchomionych w efekcie",
"  jest.runOnlyPendingTimers();",
"  jest.useRealTimers();",
"  await waitFor(() => {",
"    expect(screen.getByText('Twój Asystent AI')).toBeTruthy();",
"  });",
"});"
)
W $testPath ($lines -join "`r`n")
Set-Location -LiteralPath $projectRoot
& npx jest --clearCache | Out-Host
& npm test | Out-Host
Write-Host "DONE"
