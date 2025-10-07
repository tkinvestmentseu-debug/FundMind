Write-Host "== FIX PremiumAiBanner =="

# 1. Utwórz katalog _components
$compDir = "D:\FundMind\app\_components"
if (!(Test-Path $compDir)) { New-Item -ItemType Directory -Path $compDir | Out-Null }

# 2. Zarchiwizuj stary plik
$bannerFile = "$compDir\PremiumAiBanner.tsx"
if (Test-Path $bannerFile) {
  $bak = "$bannerFile.bak.$(Get-Date -Format yyyyMMddHHmmss)"
  Move-Item $bannerFile $bak -Force
  Write-Host "✓ Archiwizowano -> $bak"
}

# 3. Zapisz nowy PremiumAiBanner
$newBanner = @"
import React from "react";
import { TouchableOpacity, Text, StyleSheet, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { useRouter } from "expo-router";

export default function PremiumAiBanner() {
  const router = useRouter();
  return (
    <TouchableOpacity
      style={styles.container}
      activeOpacity={0.9}
      onPress={() => router.push("/ai")}
    >
      <LinearGradient
        colors={["#d5b3ff", "#a678ff"]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.gradient}
      >
        <View style={styles.iconCircle}>
          <Text style={styles.iconText}>AI</Text>
        </View>
        <Text style={styles.text}>Twój Asystent AI</Text>
      </LinearGradient>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    marginVertical: 12,
    marginHorizontal: 20,
    borderRadius: 12,
    overflow: "hidden",
  },
  gradient: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 12,
    borderRadius: 12,
  },
  iconCircle: {
    width: 26,
    height: 26,
    borderRadius: 13,
    borderWidth: 1,
    borderColor: "white",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 8,
  },
  iconText: {
    color: "white",
    fontWeight: "bold",
    fontSize: 12,
  },
  text: {
    color: "white",
    fontSize: 15,
    fontWeight: "600",
  },
});
"@
$newBanner | Set-Content -Path $bannerFile -Encoding UTF8
Write-Host "✓ Nadpisano PremiumAiBanner.tsx -> $bannerFile"

# 4. Napraw import i użycie w index.tsx
$indexPath = "D:\FundMind\app\(tabs)\index.tsx"
if (Test-Path $indexPath) {
  $src = Get-Content $indexPath -Raw
  $src = $src -replace 'import .*AiBanner.*;\r?\n',''
  if ($src -notmatch 'PremiumAiBanner') {
    $src = "import PremiumAiBanner from `"../_components/PremiumAiBanner`";`r`n" + $src
  }
  $src = $src -replace '(<|</)AiBanner','`$1PremiumAiBanner'
  Set-Content -Path $indexPath -Value $src -Encoding UTF8
  Write-Host "✓ Naprawiono index.tsx"
}

# 5. Restart Expo z logami osobno
$logsDir = "D:\FundMind\logs"
if (!(Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir | Out-Null }
$ts = Get-Date -Format yyyyMMddHHmmss
$logOut = "$logsDir\fix-premium-banner-$ts.out.log"
$logErr = "$logsDir\fix-premium-banner-$ts.err.log"

Write-Host "== Start Expo (clear cache) =="
Start-Process -FilePath "npx" `
  -ArgumentList "expo start --clear" `
  -WorkingDirectory "D:\FundMind" `
  -RedirectStandardOutput $logOut `
  -RedirectStandardError $logErr
