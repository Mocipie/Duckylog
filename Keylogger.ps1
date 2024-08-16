# Function to download and execute a PowerShell script from a GitHub repository
function Execute-GitHubScript {
    param (
        [string]$scriptUrl,
        [string]$localScriptPath = "$env:TEMP\downloaded_script.ps1"
    )

    # Download the script from the GitHub repository
    Invoke-WebRequest -Uri $scriptUrl -OutFile $localScriptPath

    # Execute the downloaded script
    & $localScriptPath

    # Clean up the downloaded script
    Remove-Item -Path $localScriptPath -Force
}

# URL of the PowerShell script from the GitHub repository
$scriptUrl = "https://raw.githubusercontent.com/YourUsername/YourRepo/main/YourScript.ps1"

# Execute the script from the GitHub repository
Execute-GitHubScript -scriptUrl $scriptUrl
