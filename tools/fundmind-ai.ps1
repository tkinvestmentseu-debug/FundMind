param([string]$task,[switch]$auto,[string]$model="gpt-4o")
$projectRoot="D:\FundMind";$toolsDir=Join-Path $projectRoot "tools"
$mode=if($auto){"AUTO"}else{"SEMI"}
$parts=@(
"You are an AI assistant helping to build the application FundMind.",
"Project root: D:\FundMind",
"Stack: Expo React Native, TypeScript, expo-router.",
"Mode: $mode",
"Task: $task")
$prompt=[string]::Join("`n",$parts)
if($auto){& $toolsDir\chatgpt-bridge.ps1 $prompt -auto -model $model}else{& $toolsDir\chatgpt-bridge.ps1 $prompt -model $model}

