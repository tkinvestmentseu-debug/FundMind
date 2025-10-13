# 01d-rewrite-app-config.ps1 — Rekonstrukcja app.config.ts (kanoniczny)
$ErrorActionPreference = "Stop"
$root = "D:\FundMind"
$appCfgPath = Join-Path $root "app.config.ts"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
function ReadRaw([string]$p){ if(!(Test-Path $p)){ throw "Brak pliku: $p" }; Get-Content -Raw -LiteralPath $p }
function WriteUtf8([string]$p,[string]$s){ [IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false)) }
function Tpl([string]$tpl,[hashtable]$kv){ foreach($k in $kv.Keys){ $tpl=$tpl.Replace("{{${k}}}",[string]$kv[$k]) } $tpl }
$appText = ReadRaw $appCfgPath
$nameMatch   = [regex]::Match($appText, 'name\s*:\s*["'']([^"'']+)["'']')
$bundleMatch = [regex]::Match($appText, 'bundleIdentifier\s*:\s*["'']([^"'']+)["'']')
$expoName    = if($nameMatch.Success){ $nameMatch.Groups[1].Value } else { "FundMind" }
$bundleId    = if($bundleMatch.Success){ $bundleMatch.Groups[1].Value } else { "com.fundmind.app" }
Copy-Item -Force $appCfgPath "$appCfgPath.bak.$ts"
$template = @"
import "dotenv/config";

export default {
  expo: {
    name: "{{APP_NAME}}",
    slug: "fundmind",
    scheme: "fundmind",
    version: "0.1.0",
    orientation: "portrait",
    userInterfaceStyle: "automatic",
    icon: "./assets/icon.png",
    splash: { image: "./assets/splash.png", resizeMode: "contain", backgroundColor: "#ffffff" },
    ios: {
      supportsTablet: true,
      bundleIdentifier: "{{BUNDLE_ID}}",
      infoPlist: {
        UIBackgroundModes: ["remote-notification"],
        NSCameraUsageDescription: "We use camera for document OCR scanning."
      }
    },
    android: {
      package: "{{BUNDLE_ID}}",
      adaptiveIcon: { foregroundImage: "./assets/adaptive-icon.png", backgroundColor: "#ffffff" },
      permissions: ["CAMERA", "VIBRATE", "POST_NOTIFICATIONS"],
      useNextNotificationsApi: true
    },
    extra: { eas: { projectId: "00000000-0000-0000-0000-000000000000" } },
    plugins: [
      "expo-router",
      ["expo-notifications", { "sounds": [] }],
      "expo-sqlite",
      "expo-localization"
    ]
  }
};
"@
$out = Tpl $template @{ APP_NAME=$expoName; BUNDLE_ID=$bundleId }
WriteUtf8 $appCfgPath $out
Write-Host "[OK] app.config.ts zrekonstruowany. name='$expoName', bundleIdentifier='$bundleId'. Backup: $appCfgPath.bak.$ts"