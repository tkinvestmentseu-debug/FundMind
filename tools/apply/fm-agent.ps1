param([ValidateSet("ThemeFix")] [string]$Action = "ThemeFix")
$ErrorActionPreference="Stop"
function Backup-File([string]$p){ if(Test-Path $p){ Copy-Item $p "$p.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Force } }
function Ensure-Dir([string]$p){ $d = Split-Path $p -Parent; if($d){ New-Item -ItemType Directory -Force -Path $d | Out-Null } }
function Write-FileLines([string]$path,[string[]]$lines){ Ensure-Dir $path; Backup-File $path; $lines | Set-Content $path -Encoding UTF8 }
if($Action -eq "ThemeFix"){
  # theme.tsx — jasny/ciemny/auto z persystencją
  $themeLines = @(
    "import React, { createContext, useContext, useEffect, useMemo, useState } from ""react"";"
    "import { NavigationContainer, DarkTheme as NavDark, DefaultTheme as NavLight, Theme as NavTheme } from ""@react-navigation/native"";"
    "import { useColorScheme } from ""react-native"";"
    ""
    "type ThemeMode = ""light"" | ""dark"" | ""system"";"
    "type Resolved = ""light"" | ""dark"";"
    ""
    "type ThemeContextValue = { mode: ThemeMode; setMode: (m: ThemeMode) => void; resolved: Resolved };"
    "const ThemeModeContext = createContext<ThemeContextValue | undefined>(undefined);"
    "export function useThemeMode(){ const ctx = useContext(ThemeModeContext); if(!ctx) throw new Error(""useThemeMode must be used within AppThemeProvider""); return ctx; }"
    "export function AppThemeProvider({ children }: { children: React.ReactNode }) {"
    "  const system = (useColorScheme() ?? ""light"") as Resolved;"
    "  const [mode, setMode] = useState<ThemeMode>(""system"");"
    "  const resolved: Resolved = (mode === ""system"" ? system : mode) as Resolved;"
    "  const theme: NavTheme = resolved === ""dark"" ? NavDark : NavLight;"
    "  useEffect(() => { let cancelled=false; (async()=>{ try { const mod:any = await import(""@react-native-async-storage/async-storage""); const S = mod?.default ?? mod; const saved = await S.getItem(""fm.theme.mode""); if(!cancelled && (saved === ""light"" || saved === ""dark"" || saved === ""system"")) setMode(saved); } catch{} })(); return ()=>{cancelled=true}; }, []);"
    "  useEffect(() => { (async()=>{ try { const mod:any = await import(""@react-native-async-storage/async-storage""); const S = mod?.default ?? mod; await S.setItem(""fm.theme.mode"", mode); } catch{} })(); }, [mode]);"
    "  const ctx = useMemo(()=>({mode,setMode,resolved}),[mode,resolved]);"
    "  return (<ThemeModeContext.Provider value={ctx}><NavigationContainer theme={theme}>{children}</NavigationContainer></ThemeModeContext.Provider>);"
    "}"
  )
  Write-FileLines "app\_providers\theme.tsx" $themeLines
  # settings/index.tsx — przełącznik motywu
  $settingsLines = @(
    "import React from ""react"";"
    "import { View, Text, Pressable, StyleSheet } from ""react-native"";"
    "import { useThemeMode } from ""../../_providers/theme"";"
    "function Choice({ label, active, onPress }: { label: string; active: boolean; onPress: () => void }) { return (<Pressable onPress={onPress} style={[styles.chip, active && styles.chipActive]}><Text style={[styles.chipText, active && styles.chipTextActive]}>{label}</Text></Pressable>); }"
    "export default function SettingsScreen() { const { mode, setMode, resolved } = useThemeMode(); return ( <View style={styles.container}><Text style={styles.h1}>Ustawienia</Text><Text style={styles.label}>Motyw</Text><View style={styles.row}><Choice label=""Jasny"" active={mode === ""light""} onPress={()=>setMode(""light"")} /><Choice label=""Ciemny"" active={mode === ""dark""} onPress={()=>setMode(""dark"")} /><Choice label=""Auto"" active={mode === ""system""} onPress={()=>setMode(""system"")} /></View><Text style={styles.help}>Bieżący efekt: {resolved}</Text></View> ); }"
    "const styles = StyleSheet.create({ container:{flex:1,padding:16,gap:12}, h1:{fontSize:22,fontWeight:""600"",marginBottom:8}, label:{fontSize:16,opacity:0.8}, row:{flexDirection:""row"",columnGap:8,gap:8}, chip:{paddingVertical:8,paddingHorizontal:12,borderRadius:999,borderWidth:1,borderColor:"#888"}, chipActive:{backgroundColor:"#555"",borderColor:"#555""}, chipText:{color:"#222"}, chipTextActive:{color:"#fff""} });"
  )
  Write-FileLines "app\(tabs)\settings\index.tsx" $settingsLines
  # _layout.tsx — domknięte tagi
  $layoutLines = @(
    "import React from ""react"";"
    "import { Slot } from ""expo-router"";"
    "import { SafeAreaProvider } from ""react-native-safe-area-context"";"
    "import { AppThemeProvider } from ""./_providers/theme"";"
    "export default function RootLayout() { return ( <AppThemeProvider><SafeAreaProvider><Slot /></SafeAreaProvider></AppThemeProvider> ); }"
  )
  Write-FileLines "app\_layout.tsx" $layoutLines
}
Write-Host "OK" -ForegroundColor Green
