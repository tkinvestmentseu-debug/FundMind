param()

$projectRoot = "D:\FundMind"

Write-Host "== Archiwizacja starego PremiumAiBanner =="
$oldBanner = Join-Path $projectRoot "app\_components\PremiumAiBanner.tsx"
if (Test-Path $oldBanner) {
    $bak = "$oldBanner.bak.$(Get-Date -Format yyyyMMddHHmmss)"
    Move-Item $oldBanner $bak -Force
    Write-Host "Stary banner zarchiwizowany jako $bak"
}

Write-Host "== Tworzenie nowego PremiumAiBanner =="
$newBannerCode = @"
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
        colors={["#b07bff", "#8a4fff"]}
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
    marginVertical: 16,
    marginHorizontal: 20,
    borderRadius: 12,
    overflow: "hidden",
  },
  gradient: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 14,
    borderRadius: 12,
  },
  iconCircle: {
    width: 28,
    height: 28,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "white",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 10,
  },
  iconText: {
    color: "white",
    fontWeight: "bold",
    fontSize: 12,
  },
  text: {
    color: "white",
    fontSize: 16,
    fontWeight: "600",
  },
});
"@

$newBannerPath = Join-Path $projectRoot "app\_components\PremiumAiBanner.tsx"
$newBannerCode | Set-Content -Path $newBannerPath -Encoding UTF8
Write-Host "Nowy PremiumAiBanner utworzony w $newBannerPath"

Write-Host "== Aktualizacja index.tsx =="
$indexPath = Join-Path $projectRoot "app\(tabs)\index.tsx"
if (Test-Path $indexPath) {
    $content = Get-Content $indexPath -Raw
    $content = $content -replace 'import .*Premium.*AiBanner.*;\r?\n',''
    if ($content -notmatch 'PremiumAiBanner') {
        $content = "import PremiumAiBanner from `"../_components/PremiumAiBanner`";`r`n" + $content
    }
    $content = $content -replace '(<|</)AiBanner','`$1PremiumAiBanner'
    Set-Content -Path $indexPath -Value $content -Encoding UTF8
    Write-Host "Plik index.tsx zaktualizowany"
}
