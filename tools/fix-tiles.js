// tools/fix-tiles.js
// Start -> "Inwestycje"; Kalendarz -> "Kursy walut"
// Backupy: *.bak.<timestamp>.tsx; tylko dwa pliki.

const fs = require("fs");
const path = require("path");

const ROOT = "D:\\FundMind";
const APP = path.join(ROOT, "app");

function ts() {
  const d = new Date();
  const p = n => String(n).padStart(2, "0");
  return d.getFullYear().toString()+p(d.getMonth()+1)+p(d.getDate())+"-"+p(d.getHours())+p(d.getMinutes())+p(d.getSeconds());
}

function firstScreenPath() {
  const c = [
    path.join(APP, "(tabs)", "index.tsx"),
    path.join(APP, "tabs", "index.tsx"),
    path.join(APP, "index.tsx"),
  ];
  return c.find(fs.existsSync);
}

function secondScreenPath() {
  const c = [
    path.join(APP, "(tabs)", "calendar", "index.tsx"),
    path.join(APP, "tabs", "calendar", "index.tsx"),
  ];
  return c.find(fs.existsSync);
}

function backup(p) {
  const bak = p + ".bak." + ts();
  fs.copyFileSync(p, bak);
  return bak;
}

function replaceIfContains(file, fromStr, toStr) {
  const src = fs.readFileSync(file, "utf8");
  if (!src.includes(fromStr)) return false;
  const bak = backup(file);
  const out = src.split(fromStr).join(toStr);
  fs.writeFileSync(file, out, "utf8");
  console.log(`[OK] ${path.relative(ROOT, file)}: "${fromStr}" -> "${toStr}" (backup: ${path.basename(bak)})`);
  return true;
}

(function run(){
  const first = firstScreenPath();
  const second = secondScreenPath();

  if (!first)  { console.error("[ERR] Nie znaleziono pliku 1. ekranu (index.tsx)."); process.exit(1); }
  if (!second) { console.error("[ERR] Nie znaleziono pliku 2. ekranu (calendar/index.tsx)."); process.exit(1); }

  // 2. ekran (Kalendarz): ma miec "Kursy walut"
  const ch2 = replaceIfContains(second, "Inwestycje", "Kursy walut");

  // 1. ekran (Start): ma miec "Inwestycje"
  const ch1 = replaceIfContains(first, "Kursy walut", "Inwestycje");

  if (!ch1 && !ch2) console.log("[INFO] Brak zmian — etykiety juz byly poprawne.");
  else console.log("[DONE] Start=Inwestycje, Kalendarz=Kursy walut.");
})();
