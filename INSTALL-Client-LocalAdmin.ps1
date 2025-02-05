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

if ($install)
{
    Start-Transcript -path $logFile -Append
        try
        {         
            #Get Join ID
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"
            $JoinInfoPath = (Get-ChildItem -Path $regPath).Name
            $JoinID = Split-Path $JoinInfoPath -Leaf
            Write-Host "Join ID: $JoinID"

            #Get Enrolloment UPN
            $PUUser = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$JoinID" -Name UserEmail).UserEmail
            $currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName
            Write-Host "Enrollment User: $PUUSer"
            Write-Host "Current User: $currentUser"

            #Get admin group name
            $sysLang = (Get-WinSystemLocale).Name
            $adminGroup = "Administrators"
            if ($sysLang -eq "de-DE") {
                $adminGroup = "Administratoren"
            } else {
                $adminGroup = "Administrators"
            }

            #If on W365 and PUUSer is "fooUser@*" then set PUUser to current user
            if (([regex]::Escape($PUUser) -like "fooUser@*") -and ((Get-WmiObject -Class Win32_ComputerSystem).Name -like "CPC*")) {
                Write-Host "Running on W365. PUUser cannot match. Setting PUUser to current user."
                $PUUser = $currentUser
            } else {
                Write-Host "Not Running on W365. PUUser can match."
            }

            # Match onprem domain user with upn
            if ([regex]::Escape($PUUser) -notmatch [regex]::Escape($currentUser)) {
                New-LocalGroup -Name ADMTEST | Out-Null
                Add-LocalGroupMember -Group "ADMTEST" -Member "azuread\$PUUser" | Out-Null
                $TranslatedPUUser = (Get-LocalGroupMember -Group "ADMTEST").Name

                Write-Host "$PUUser is translated to $TranslatedPUUser"

                if ($TranslatedPUUser -eq $currentUser) {
                    if ($TranslatedPUUser -like 'fra\*') {
                        $TranslatedPUUser = $TranslatedPUUser -replace '^fra\\', ''
                    }
                    $PUUser = $TranslatedPUUser
                    Write-Host "Setting PUUser to $PUUser"
                } else {
                    Write-Host "ERROR PU UPN not matching CU UPN."
                }
            }

            #Check if enrollment username matches currently logged on username
            function Test-LocalGroupMember {
                param (
                    [string]$GroupName,
                    [string]$UserName
                )
            
                $groupMembers = Get-LocalGroupMember -Group $GroupName
                foreach ($member in $groupMembers) {
                    if ($member.Name -eq $UserName) {
                        return $true
                    }
                }
                return $false
            }
            
            #Add enrollment user to local admin group if current user is matching
            if (Test-LocalGroupMember -GroupName "ADMTEST" -UserName "FRA\$PUUser") {
                Write-Host "$currentUser is matching with $PUUSer and in ADMTEST Group."

                if (Test-LocalGroupMember -GroupName $adminGroup -UserName $currentUser) {
                    Write-Host "$currentUser is already in $adminGroup group."
                } else {   
                    $EnrollmentUPN = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$JoinID" -Name UserEmail).UserEmail
                    Write-Host "Adding $EnrollmentUPN to $adminGroup group."
                    Add-LocalGroupMember -Group $adminGroup -Member "azuread\$EnrollmentUPN" | Out-Null
                }
                Remove-LocalGroup -Name "ADMTEST"
                exit 0
            } else {
                Write-Host "$currentUser is not matching with $PUUSer. Exiting."
                Remove-LocalGroup -Name "ADMTEST"
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
        #Get Join ID
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"
        $JoinInfoPath = (Get-ChildItem -Path $regPath).Name
        $JoinID = Split-Path $JoinInfoPath -Leaf
        Write-Host "Join ID: $JoinID"

        #Get Enrolloment UPN
        $PUUser = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$JoinID" -Name UserEmail).UserEmail
        $currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName
        Write-Host "Enrollment User: $PUUSer"
        Write-Host "Current User: $currentUser"

        #Get admin group name
        $sysLang = (Get-WinSystemLocale).Name
        $adminGroup = "Administrators"
        if ($sysLang -eq "de-DE") {
            $adminGroup = "Administratoren"
        } else {
            $adminGroup = "Administrators"
        }

        #If on W365 and PUUSer is "fooUser@*" then set PUUser to current user
        if (([regex]::Escape($PUUser) -like "fooUser@*") -and ((Get-WmiObject -Class Win32_ComputerSystem).Name -like "CPC*")) {
            Write-Host "Running on W365. PUUser cannot match. Setting PUUser to current user."
            $PUUser = $currentUser
        } else {
            Write-Host "Not Running on W365. PUUser can match."
        }

        # Match onprem domain user with upn
        if ([regex]::Escape($PUUser) -notmatch [regex]::Escape($currentUser)) {
            New-LocalGroup -Name ADMTEST | Out-Null
            Add-LocalGroupMember -Group "ADMTEST" -Member "azuread\$PUUser" | Out-Null
            $TranslatedPUUser = (Get-LocalGroupMember -Group "ADMTEST").Name

            Write-Host "$PUUser is translated to $TranslatedPUUser"

            if ($TranslatedPUUser -eq $currentUser) {
                if ($TranslatedPUUser -like 'fra\*') {
                    $TranslatedPUUser = $TranslatedPUUser -replace '^fra\\', ''
                }
                $PUUser = $TranslatedPUUser
                Write-Host "Setting PUUser to $PUUser"
            } else {
                Write-Host "ERROR PU UPN not matching CU UPN."
            }
        }

        #Check if enrollment username matches currently logged on username
        function Test-LocalGroupMember {
            param (
                [string]$GroupName,
                [string]$UserName
            )
        
            $groupMembers = Get-LocalGroupMember -Group $GroupName
            foreach ($member in $groupMembers) {
                if ($member.Name -eq $UserName) {
                    return $true
                }
            }
            return $false
        }
        
        #Add enrollment user to local admin group if current user is matching
        if (Test-LocalGroupMember -GroupName "ADMTEST" -UserName "FRA\$PUUser") {
            Write-Host "$currentUser is matching with $PUUSer and in ADMTEST Group."

            if (Test-LocalGroupMember -GroupName $adminGroup -UserName $currentUser) {
                
                $EnrollmentUPN = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$JoinID" -Name UserEmail).UserEmail
                Write-Host "Removing $EnrollmentUPN from $adminGroup group."
                Remove-LocalGroupMember -Group $adminGroup -Member "azuread\$EnrollmentUPN" | Out-Null
            } else {   
                Write-Host "$currentUser is not in $adminGroup group."
            }
            Remove-LocalGroup -Name "ADMTEST"
            exit 0
        } else {
            Write-Host "$currentUser is not matching with $PUUSer. Exiting."
            Remove-LocalGroup -Name "ADMTEST"
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