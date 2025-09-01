#!/bin/bash
set -euo pipefail

# Automatyczny skrypt do aktualizacji Expo do SDK 53

echo "🔧 Rozpoczynam upgrade do Expo SDK 53…"

# 1) utwórz nowy branch dla aktualizacji
branch="chore/expo53-upgrade-$(date +%Y%m%d%H%M)"
git checkout -b "$branch" || true

# 2) zainstaluj nową wersję expo
npm install expo@^53.0.0

# 3) dopasuj zależności do SDK (automatycznie dobierze wersje)
npx expo install --fix

# 4) healthcheck (nie przerywa skryptu, tylko raportuje)
npx expo-doctor || true

# 5) jeżeli projekt zawiera katalogi ios lub android (prebuild), odśwież je
if [ -d ios ] || [ -d android ]; then
  echo "♻️  Odświeżam projekty natywne (prebuild)…"
  mkdir -p .backup
  [ -d ios ] && mv ios ".backup/ios_$(date +%s)" || true
  [ -d android ] && mv android ".backup/android_$(date +%s)" || true
  npx expo prebuild --clean
fi

# 6) commit i push

git add -A
git commit -m "chore: upgrade to Expo SDK 53 + deps fix"
git push -u origin "$branch"

echo "✅ Gotowe. Otwórz Expo Go i uruchom projekt jeszcze raz."
