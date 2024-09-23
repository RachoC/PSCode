param (
    [string[]]$args
)

Add-Type -AssemblyName System.Windows.Forms
# Define the function to hide the window
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}
"@

# Constants for ShowWindowAsync
$HideWindConst = 0
$ShowWindConst = 1

# Get the handle of the console window
$hWnd = [Win32]::GetConsoleWindow()

# Change the window visibility
[Win32]::ShowWindowAsync($hWnd, $HideWindConst) | Out-Null

$TestVar = $false
$hiddenMode = $false
$VencordUpdateFound = $false
$matchedVersion = $null

$lockFilePath = "$env:TEMP\VencordReinstallStartupScript.lock"

$discordPath = "$env:LocalAppData\Discord"
$vencordInstallerPath = "$env:LocalAppData\Discord\VencordInstallerCli.exe"
$discordLaunchPath = "$env:LocalAppData\Discord\Update.exe"

$vencordInstallerUrl = "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"



function Wait-ForInternet {
    param (
        [string]$Target = "www.google.com",
        [int]$Timeout = 5
    )

    while ($true) {
        $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        if ($adapter) {
            $connection = Test-NetConnection -ComputerName $Target -InformationLevel Quiet
            if ($connection) {
                Write-Host "Internet connection is available."
                break
            }
        }

        # Get the handle of the console window
        $hWnd = [Win32]::GetConsoleWindow()

        # Change the window visiblity
        [Win32]::ShowWindowAsync($hWnd, $ShowWindConst) | Out-Null

        Write-Warning "Waiting for internet connection... Waiting 5 Secconds till next try."
        Set-Variable -Name hiddenMode -Value $false -Scope Global
        Start-Sleep -Seconds $Timeout
    }
}



function Update-VencordInstaller {
    Write-Output "Installing Newest Vencord Version"
    Invoke-WebRequest -Uri $vencordInstallerUrl -OutFile $vencordInstallerPath
    Write-Output "Vencord Installer updated successfully."
    Write-Output ""
}

function Get-CurrentVencordVersion {
    if (Test-Path $vencordInstallerPath) {
        $versionOutput = & $vencordInstallerPath --version 2>&1

        #Write-Output "Version output: $versionOutput"

        $versionMatch = $versionOutput | Select-String -Pattern "v(\d+\.\d+\.\d+)"
        if ($versionMatch) {
            $matchedVersion = $versionMatch.Matches[0].Groups[1].Value
            Set-Variable -Name matchedVersion -Value $matchedVersion -Scope Global
            Write-Output "Version Of Current Install: $matchedVersion"
        } else {
            Write-Output "Failed to parse version from output: $versionOutput"
            Set-Variable -Name matchedVersion -Value "0.0.0" -Scope Global
        }
    } else {
        Write-Output "Vencord Installer not found at path: $vencordInstallerPath"
        Set-Variable -Name matchedVersion -Value "0.0.0" -Scope Global
    }
}

function Check-ForVencordUpdate {
    $url = "https://api.github.com/repos/Vencord/Installer/releases/latest"
    try {
        $global:response = Invoke-RestMethod -Uri $url
        $global:latestVersion = $global:response.tag_name.TrimStart('v')
        # Place any additional code that should run if the request is successful here
    }
    catch {

        # Get the handle of the console window
        $hWnd = [Win32]::GetConsoleWindow()

        # Change the window visiblity
        [Win32]::ShowWindowAsync($hWnd, $ShowWindConst) | Out-Null
    
        $errorMessage = $_
        $rateLimitExceeded = $errorMessage | Select-String -Pattern "API rate limit exceeded for"
        if ($rateLimitExceeded) {

            Write-Warning "API rate limit exceeded for Github. Please try again later in an hour."
            Start-Sleep -Seconds 1
            Write-Output ""
            Write-Output "Skipping Rest Of The Code..."

            Start-Sleep -Milliseconds 250

            Read-Host -Prompt "Press Enter to exit & Open Discord:"

        } else {

            Write-Warning "An error occurred: $_.Exception.Message : Please Contact Script Owner."
            Start-Sleep -Seconds 1
            Write-Output ""
            Write-Output "Skipping Rest Of The Code..."

            Start-Sleep -Milliseconds 250

            Read-Host -Prompt "Press Enter to exit & Open Discord:"

        }

       # Remove-Item -Path $lockFilePath -Force

        #Start-Sleep -Seconds 5
        Start-Process -FilePath $discordLaunchPath -ArgumentList "--processStart Discord.exe"
        exit
        # Optionally, you can add any cleanup or logging code here
    }
    Get-CurrentVencordVersion

    #Start-Sleep -Seconds 1

    Write-Output ""

    if ($latestVersion -ne $matchedVersion) {
        Write-Output "Current Version: $matchedVersion"
        Write-Output "Update Version available: $latestVersion"
        Write-Output ""
        if (!$TestVar){
            Update-VencordInstaller
        }
        Write-Output "Vencord CLI has been updated to version $latestVersion"
        Write-Output ""
        $VencordUpdateFound = $true
    } else {
        Write-Output "You are using the latest version."
    }
}

# Check if "debug" argument is present
if ($args -contains "-Debug") {
    $TestVar = $true
    $hiddenMode = $false
    Write-Output "Debug Enabled"
} elseif ($args -contains "-DisableHidden") {
    $hiddenMode = $false
} else {
    $hiddenMode = $true
}

# Start a hidden PowerShell process to run the script if not already in hidden mode and not in debug mode
if (($hiddenMode -or $TestVar) -and -not (Test-Path $lockFilePath)) {
    New-Item -Path $lockFilePath -ItemType File -Force
    $scriptPath = $MyInvocation.MyCommand.Path
    #$arguments = $args + "hidden" -join ' '
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File "$scriptPath" $arguments"
    exit
}


Wait-ForInternet

if (Test-Path $discordPath) {

    #$hiddenMode = $true # Showcase Overide

    # Check if Discord is running
    if (Get-Process -Name discord -ErrorAction SilentlyContinue) {
        Get-Process -Name discord | Stop-Process -Force
        Write-Output "Discord process stopped."
        Write-Output ""
    } else {
        Write-Output "Discord is not running."
        Write-Output ""
    }

    Check-ForVencordUpdate
    Write-Output ""
    if ($VencordUpdateFound) {
        Start-Process -WindowStyle Hidden -FilePath $vencordInstallerPath -ArgumentList "--install --location $discordPath" #-Wait

        #[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

        Start-Sleep -Milliseconds 3800
        Write-Output "Vencord reinstalled successfully."
        Write-Output ""
        Get-Process -Name VencordInstallerCli | Stop-Process -Force
    }

    if (!$TestVar){
        Start-Process -FilePath $discordLaunchPath -ArgumentList "--processStart Discord.exe"
    }

    if ($TestVar -or !$hiddenMode) {
        Read-Host -Prompt "Press Enter to exit"
    }
} else {
    Write-Output "Discord is not installed."
    if ($TestVar -or $hiddenMode) {
        Read-Host -Prompt "Press Enter to exit, WHY DO YOU NOT HAVE DISCORD"
    }
}

# Clean up the lock file
if (Test-Path $lockFilePath) {
    Remove-Item -Path $lockFilePath -Force
}


