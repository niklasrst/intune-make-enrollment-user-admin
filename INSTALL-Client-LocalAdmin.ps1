<#
    .SYNOPSIS 
    Windows Software packaging wrapper

    .DESCRIPTION
    Install:   C:\Windows\SysNative\WindowsPowershell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -Command .\INSTALL-Client-LocalAdmin.ps1 -install
    Uninstall: C:\Windows\SysNative\WindowsPowershell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -Command .\INSTALL-Client-LocalAdmin.ps1 -uninstall
    
    .ENVIRONMENT
    PowerShell 5.0
    
    .AUTHOR
    Niklas Rast
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true, ParameterSetName = 'install')]
	[switch]$install,
	[Parameter(Mandatory = $true, ParameterSetName = 'uninstall')]
	[switch]$uninstall
)

$ErrorActionPreference = "SilentlyContinue"
$logFile = ('{0}\{1}.log' -f "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs", [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))

function Test-LocalGroupMember {
    param (
        [string]$GroupName,
        [string]$UserName
    )

    $groupMembers = Get-LocalGroupMember -Group $GroupName
    foreach ($member in $groupMembers) {
        $memberSid = (New-Object System.Security.Principal.NTAccount($member.Name)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        if ($memberSid -eq $UserName) {
            return $true
        }
    }
    return $false
}

if ($install)
{
    Start-Transcript -path $logFile -Append
        try
        {         
            #Get Enrolloment UPN
            $currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName
            $currentUserSid = (New-Object System.Security.Principal.NTAccount($currentUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

            #Get admin group name
            $sysLang = (Get-WinSystemLocale).Name
            $adminGroup = "Administrators"
            if ($sysLang -eq "de-DE") {
                $adminGroup = "Administratoren"
            } else {
                $adminGroup = "Administrators"
            }

            #Add user to Admin group
            Add-LocalGroupMember -Group $adminGroup -Member $currentUserSid | Out-Null

            #Validate
            if (Test-LocalGroupMember -GroupName $adminGroup -UserName $currentUserSid) {
                Write-Host "Successfully added $currentUser ($currentUserSid) to $adminGroup group."
                exit 0
            } else {
                Write-Host "Failed to add $currentUser ($currentUserSid) to $adminGroup group."
                exit 1
            }
        } 
        catch
        {
            $PSCmdlet.WriteError($_)
            exit 1
        }
    Stop-Transcript
}

if ($uninstall)
{
    Start-Transcript -path $logFile -Append
    try
    {         
        #Get User SID
        $currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName
        $currentUserSid = (New-Object System.Security.Principal.NTAccount($currentUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

        #Get admin group name
        $sysLang = (Get-WinSystemLocale).Name
        $adminGroup = "Administrators"
        if ($sysLang -eq "de-DE") {
            $adminGroup = "Administratoren"
        } else {
            $adminGroup = "Administrators"
        }

        #Remove user from Admin group
        Remove-LocalGroupMember -Group $adminGroup -Member $currentUserSid | Out-Null
        
        #Validate
        if (Test-LocalGroupMember -GroupName $adminGroup -UserName $currentUser) {
            Write-Host "Failed to remove $currentUser ($currentUserSid) from $adminGroup group."
            exit 1
        } else {
            Write-Host "Removed $currentUser ($currentUserSid) from $adminGroup group."
            exit 0
        }
    } 
    catch
    {
        $PSCmdlet.WriteError($_)
        exit 1
    }
    Stop-Transcript
}