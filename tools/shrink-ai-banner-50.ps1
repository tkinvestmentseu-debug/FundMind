# Shrink AI banner inside FM-AI-BANNER markers
$ErrorActionPreference = "Stop"
$project = "D:\FundMind"
$file = Join-Path $project "app\index.tsx"
if (!(Test-Path $file)) { throw "index.tsx not found" }

$backup = "$file.bak." + (Get-Date -Format yyyyMMddHHmmss)
Copy-Item $file $backup -Force
Write-Output ("Backup: " + $backup)

function Shrink-Classes([string]$s){
  # font sizes: one step down
  $s = $s -replace '\btext-lg\b','text-base'
  $s = $s -replace '\btext-base\b','text-sm'
  $s = $s -replace '\btext-sm\b','text-xs'
  # padding: approx half (p-*, py-*, px-*)
  $s = $s -replace '\bp-6\b','p-3'
  $s = $s -replace '\bp-5\b','p-2'
  $s = $s -replace '\bp-4\b','p-2'
  $s = $s -replace '\bp-3\b','p-1'
  $s = $s -replace '\bp-2\b','p-1'
  $s = $s -replace '\bpy-6\b','py-3'
  $s = $s -replace '\bpy-5\b','py-2'
  $s = $s -replace '\bpy-4\b','py-2'
  $s = $s -replace '\bpy-3\b','py-1'
  $s = $s -replace '\bpy-2\b','py-1'
  $s = $s -replace '\bpx-6\b','px-3'
  $s = $s -replace '\bpx-5\b','px-2'
  $s = $s -replace '\bpx-4\b','px-2'
  $s = $s -replace '\bpx-3\b','px-1'
  $s = $s -replace '\bpx-2\b','px-1'
  return $s
}

$c = Get-Content $file -Raw

$startTag = "FM-AI-BANNER START"
$endTag   = "FM-AI-BANNER END"

if ($c.Contains($startTag) -and $c.Contains($endTag)) {
  $start = $c.IndexOf($startTag)
  $end   = $c.IndexOf($endTag)
  if ($end -le $start) { throw "Marker order invalid" }

  # Expand to include some context around markers
  $pre  = $c.Substring(0, $start)
  $mid  = $c.Substring($start, ($end + $endTag.Length) - $start)
  $post = $c.Substring($end + $endTag.Length)

  $shrunk = Shrink-Classes $mid

  if ($shrunk -ne $mid) {
    $out = $pre + $shrunk + $post
    Set-Content -Path $file -Value $out -Encoding UTF8
    Write-Output "OK: Banner shrunk inside markers."
  } else {
    Write-Output "INFO: Nothing to change (already minimal)."
  }
}
else {
  # Fallback: shrink only lines near 'FundMind' occurrence, keep it scoped
  $lines = Get-Content $file
  $changed = $false
  for ($i=0; $i -lt $lines.Count; $i++){
    if ($lines[$i] -match 'FundMind' -and $lines[$i] -match 'AI') {
      # adjust this line and a small neighborhood
      $from = [Math]::Max(0, $i-5)
      $to   = [Math]::Min($lines.Count-1, $i+5)
      for ($j=$from; $j -le $to; $j++){
        $before = $lines[$j]
        $after  = Shrink-Classes $before
        if ($after -ne $before) {
          $lines[$j] = $after
          $changed = $true
        }
      }
    }
  }
  if ($changed) {
    Set-Content -Path $file -Value $lines -Encoding UTF8
    Write-Output "OK: Banner shrunk heuristically near 'FundMind AI'."
  } else {
    Write-Output "WARN: Markers not found and no heuristic match; no changes made."
  }
}
