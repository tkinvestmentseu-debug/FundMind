# tool: diagnose-and-shrink-ai-banner.ps1 (ASCII only)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function New-LogFile([string]$dir){
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $ts = Get-Date -Format yyyyMMdd-HHmmss
  return (Join-Path $dir ("ai-banner-diagnose-" + $ts + ".log"))
}
function Log([string]$lvl,[string]$msg){
  $line = "[" + (Get-Date -Format s) + "] [" + $lvl + "] " + $msg
  Add-Content -Path $global:LOG -Value $line
  Write-Host $line
}

$ROOT = "D:\FundMind"
$FILE = Join-Path $ROOT "app\index.tsx"
$LOG  = New-LogFile (Join-Path $ROOT "logs")

try {
  Log "INFO" ("File: " + $FILE)
  if (!(Test-Path $FILE)) { Log "ERROR" "index.tsx not found"; throw "FILE_NOT_FOUND" }

  $backup = "$FILE.bak." + (Get-Date -Format yyyyMMddHHmmss)
  Copy-Item $FILE $backup -Force
  Log "INFO" ("Backup: " + $backup)

  [string[]]$lines = Get-Content $FILE
  if ($lines.Count -eq 0) { Log "ERROR" "index.tsx is empty"; throw "EMPTY_FILE" }

  # Locate last clickable banner block
  $openTag = "<TouchableOpacity"; $closeTag = "</TouchableOpacity>"
  $start = -1; $end = -1

  for ($i=$lines.Count-1; $i -ge 0; $i--){
    if ($lines[$i].IndexOf($openTag) -ge 0) { $start = $i; break }
  }
  if ($start -lt 0) {
    $openTag = "<Pressable"; $closeTag = "</Pressable>"
    for ($i=$lines.Count-1; $i -ge 0; $i--){
      if ($lines[$i].IndexOf($openTag) -ge 0) { $start = $i; break }
    }
  }
  if ($start -lt 0) {
    Log "WARN" "No clickable block found (<TouchableOpacity> or <Pressable>)."
    throw "BLOCK_NOT_FOUND"
  }
  for ($j=$start; $j -lt $lines.Count; $j++){
    if ($lines[$j].IndexOf($closeTag) -ge 0) { $end = $j; break }
  }
  if ($end -lt 0) {
    Log "ERROR" ("Open tag at line " + $start + " but closing tag " + $closeTag + " not found")
    throw "UNCLOSED_BLOCK"
  }

  Log "INFO" ("Target block: lines " + $start + ".." + $end + " (" + $openTag + ")")

  # Preview around the block (safe context)
  $pvStart = [Math]::Max(0, $start-3)
  $pvEnd   = [Math]::Min($lines.Count-1, $end+3)
  $preview = $lines[$pvStart..$pvEnd] -join "`n"
  Log "INFO" ("Preview begin")
  Log "INFO" $preview
  Log "INFO" ("Preview end")

  # Token map: shrink ~50%
  $map = @{
    'text-xl'='text-lg'; 'text-lg'='text-sm'; 'text-base'='text-sm'; 'text-sm'='text-xs';
    'p-6'='p-3'; 'p-5'='p-2'; 'p-4'='p-2'; 'p-3'='p-1'; 'p-2'='p-1';
    'py-6'='py-3'; 'py-5'='py-2'; 'py-4'='py-2'; 'py-3'='py-1'; 'py-2'='py-1';
    'px-6'='px-3'; 'px-5'='px-2'; 'px-4'='px-2'; 'px-3'='px-1'; 'px-2'='px-1'
  }

  function Shrink-ClassLine([string]$line){
    $key = "className="
    $i = $line.IndexOf($key)
    if ($i -lt 0) { return @($line,0) }
    $p = $i + $key.Length
    while ($p -lt $line.Length -and [char]::IsWhiteSpace($line[$p])) { $p++ }
    if ($p -ge $line.Length) { return @($line,0) }
    $qchar = $line[$p]
    if (($qchar -ne '"') -and ($qchar -ne "'")) { return @($line,0) }
    $p++
    $q = $line.IndexOf($qchar, $p)
    if ($q -lt 0) { return @($line,0) }

    $val = $line.Substring($p, $q - $p)
    $parts = @(); $changed = 0
    foreach ($frag in ($val -split ' ')) {
      if ($frag -eq "") { continue }
      if ($map.ContainsKey($frag)) { $parts += $map[$frag]; $changed++ } else { $parts += $frag }
    }
    if ($changed -le 0) { return @($line,0) }
    $newVal = [string]::Join(" ", $parts)
    $newLine = $line.Substring(0,$p) + $newVal + $line.Substring($q)
    return @($newLine,$changed)
  }

  $total = 0
  for ($k=$start; $k -le $end; $k++){
    $res = Shrink-ClassLine $lines[$k]
    if ($res[1] -gt 0) {
      Log "INFO" ("Change at line " + $k)
      Log "INFO" ("  BEFORE: " + $lines[$k].Trim())
      Log "INFO" ("  AFTER : " + $res[0].Trim())
      $lines[$k] = $res[0]
      $total += [int]$res[1]
    }
  }

  if ($total -gt 0) {
    Set-Content -Path $FILE -Value $lines -Encoding UTF8
    Log "INFO" ("Written changes. Tokens changed: " + $total)
  } else {
    Log "WARN" "No className tokens to shrink inside target block (maybe inline-only)."
  }

  Log "INFO" "DONE"
}
catch {
  $ex = $_.Exception
  Log "FATAL" ("Type: " + $ex.GetType().FullName)
  Log "FATAL" ("Message: " + $ex.Message)
  if ($ex.InnerException) { Log "FATAL" ("Inner: " + $ex.InnerException.Message) }
  if ($ex.StackTrace)     { Log "FATAL" ("Stack: " + $ex.StackTrace) }
  Write-Error ("FAILED. See log: " + $LOG)
  exit 1
}
