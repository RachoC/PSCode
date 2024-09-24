param (
    [string[]]$args
)

Add-Type -AssemblyName System.Windows.Forms


#VERSIONS
$LocalUpdaterCurrentVersion = "v0.0.4"


#Set Window Title
$host.UI.RawUI.WindowTitle = "TGGT PowerShell Tools Manager"


$TestVar = $false
$discordPath = "$env:LocalAppData\Discord"
$vencordInstallerPath = "$env:LocalAppData\Discord\VencordInstallerCli.exe"
$startupFolder = [System.Environment]::GetFolderPath('Startup')

$PauseMenuLoop = $false

$menuOptions = @("Install Updater", "Remove Updater", "Quit")
$instructions = "Use the Up and Down arrow keys to navigate and press Enter to select an option."




if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Create a new process with elevated privileges
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Definition + "`"";
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    exit;
}



$LocalUpdaterUpdateFound = $false

$LocalUpdaterInstallerPath = $PSCommandPath
$LocalUpdaterDiscordLaunchPath = "$env:LocalAppData\Discord\Update.exe"

$LocalUpdaterInstallerUrl = "https://github.com/RachoC/PSCode/releases/latest/download/TGGTToolInstallers.ps1"



function LocalUpdaterInstall-NewVersion {
    Write-Output "Installing Newest TGGT Tool Installer Version"
    Invoke-WebRequest -Uri $LocalUpdaterInstallerUrl -OutFile $LocalUpdaterInstallerPath
    Write-Output "TGGT Tool Installer updated successfully."
    Write-Output ""
}

function LocalUpdaterGet-InstalledVersion {
    $versionMatch = $LocalUpdaterCurrentVersion | Select-String -Pattern "v(\d+\.\d+\.\d+)"
    if ($versionMatch) {
        $LocalUpdaterCurrentVersion = $versionMatch.Matches[0].Groups[1].Value
        Set-Variable -Name LocalUpdaterCurrentVersion -Value $LocalUpdaterCurrentVersion -Scope Global
        Write-Output "Version Of Current TGGT Vencord Updater Install: $LocalUpdaterCurrentVersion"
    } else {
        Write-Output "Failed to parse version from output: $versionOutput"
        Set-Variable -Name LocalUpdaterCurrentVersion -Value "0.0.0" -Scope Global
    }
}

function LocalUpdaterCheck-ForUpdate { #----------------------------------------------------
    $url = "https://api.github.com/repos/RachoC/PSCode/releases/latest"
    try {
        $global:response = Invoke-RestMethod -Uri $url
        $global:latestVersion = $global:response.tag_name.TrimStart('v')
    }
    catch {
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
        Start-Process -FilePath $LocalUpdaterDiscordLaunchPath -ArgumentList "--processStart Discord.exe"
        exit
    }
    #LocalUpdaterGet-InstalledVersion

    Write-Output ""

    $currentVersionObj = [version]$LocalUpdaterCurrentVersion.TrimStart('v')
    $latestVersionObj = [version]$global:latestVersion

    Write-Output "$currentVersionObj"
    Write-Output "$latestVersionObj"

    if ($latestVersionObj -gt $currentVersionObj) {
        Write-Output "Current Version of Updater: $LocalUpdaterCurrentVersion"
        Write-Output "Update Version of Updater available: $global:latestVersion"
        Write-Output ""
        if (!$TestVar){
            LocalUpdaterInstall-NewVersion
        }
        Write-Output "Updater has been updated to version $global:latestVersion"
        Write-Output ""
        $LocalUpdaterUpdateFound = $true

        # Rerun the script with the same arguments
        Write-Output "Rerunning the Updater with the same arguments..."
        $scriptPath = $PSCommandPath
        $arguments = $args -join " -----Updated"
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $arguments"
        exit
    } else {
        Write-Output "You are using the latest version of the updater."
        Write-Output ""
    }
}




LocalUpdaterCheck-ForUpdate






function Show-Menu {
    param (
        [int]$selectedIndex
    )
    Clear-Host
    Write-Host "TGGT's Vencord Updater Installer Menu"
    Write-Host "================ Menu ================"
    Write-Host $instructions
    Write-Host "====================================="
    for ($i = 0; $i -lt $menuOptions.Length; $i++) {
        if ($i -eq $selectedIndex) {
            Write-Host ">> $($menuOptions[$i])" -ForegroundColor Yellow
        } else {
            Write-Host "   $($menuOptions[$i])"
        }
    }
}

function Install-File-VencordUpdater {
    Set-Variable -Name PauseMenuLoop -Value $true -Scope Global


    $sourcePath = "C:\Path\To\Your\File.txt"
    $VencordUpdaterPath = "$discordPath\TGGTVencordAutoUpdater.ps1"
    $shortcutPath = [System.IO.Path]::Combine($startupFolder, "TGGTVencordAutoUpdater.vbs")
    
    Write-Host ""
    Write-Host "Installing Auto Updater..."

    Start-Sleep -Milliseconds 1000

        # Core Script (Hide When Editing) --------------------------------------------------------------------------------------------
    Write-Output "Installing Newest TGGT Vencord Updater Version"

    $LocalUpdaterInstallerUrl = "https://github.com/RachoC/PSCode/releases/latest/download/TGGTVencordAutoUpdater.ps1"

    try {
        Invoke-WebRequest -Uri $LocalUpdaterInstallerUrl -OutFile $VencordUpdaterPath -ErrorAction Stop
        Write-Output "Download successful."
    } catch {
        Write-Output "An error occurred: $_"
    }

    Write-Output "TGGT Vencord Updater Installed successfully."
    Write-Output ""
        # Core Script (Hide End) -------------------------------------------------------------------------------------------

    #THE SHORTCUT IN STARTUP

    #$WScriptObj = New-Object -ComObject "WScript.Shell"
    #$shortcut = $WScriptObj.CreateShortcut($shortcutPath)
    #$shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    #$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    #$shortcut.WindowStyle = 1
    #$shortcut.Save()
    



    # PowerShell script to create and run a .vbs script

    $vbsContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""$VencordUpdaterPath""", 0, True
"@
    # Write the .vbs script to a file in the Startup folder
    Set-Content -Path $shortcutPath -Value $vbsContent

    Write-Host "Auto Updater has been installed for your Vencord/Vendicated Install."

    Start-Sleep -Milliseconds 1500
    Set-Variable -Name PauseMenuLoop -Value $false -Scope Global
}



function Remove-File {
    Set-Variable -Name PauseMenuLoop -Value $true -Scope Global

    Write-Host ""
    Write-Host "Removing Vencord Auto Updater..."

    Start-Sleep -Milliseconds 1000

    $VencordUpdaterPath = "$discordPath/TGGTVencordAutoUpdater.ps1"
    $shortcutPath = [System.IO.Path]::Combine($startupFolder, "TGGTVencordAutoUpdater.vbs")

    Remove-Item -Path $VencordUpdaterPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $shortcutPath -Force -ErrorAction SilentlyContinue

    Write-Host "Auto Updater Removed."
    
    Start-Sleep -Milliseconds 1500
    Set-Variable -Name PauseMenuLoop -Value $false -Scope Global
}






$selectedIndex = 0
$updateSelection = $true

while ($true) {
    while ($PauseMenuLoop) {
        Start-Sleep -Milliseconds 100
    }
    
    if ($updateSelection) {
        Show-Menu -selectedIndex $selectedIndex
    }
    
    $key = [Console]::ReadKey($true).Key
    switch ($key) {
        'UpArrow' { 
            $selectedIndex = ($selectedIndex - 1) % $menuOptions.Length 
            $updateSelection = $true
        }
        'DownArrow' { 
            $selectedIndex = ($selectedIndex + 1) % $menuOptions.Length 
            $updateSelection = $true
        }
        'Enter' {
            $updateSelection = $false
            switch ($selectedIndex) {
                0 { Install-File-VencordUpdater }
                1 { Remove-File }
                2 { Write-Host "Exiting..."; Start-Sleep -Milliseconds 200; exit }
            }
        }
    }
    
    if ($selectedIndex -lt 0) { $selectedIndex = $menuOptions.Length - 1 }
}
