#Get Join ID
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"
$JoinInfoPath = (Get-ChildItem -Path $regPath).Name
$JoinID = Split-Path $JoinInfoPath -Leaf
##Write-Host "Join ID: $JoinID"

#Get Enrolloment UPN
$PUUser = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$JoinID" -Name UserEmail).UserEmail
$currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName
##Write-Host "Enrollment User: $PUUSer"
##Write-Host "Current User: $currentUser"

#If on W365 and PUUSer is "fooUser@*" then set PUUser to current user
if (([regex]::Escape($PUUser) -like "fooUser@*") -and ((Get-WmiObject -Class Win32_ComputerSystem).Name -like "CPC*")) {
    ##Write-Host "Running on W365. PUUser cannot match. Setting PUUser to current user."
    $PUUser = $currentUser
    ##Write-Host "Setting PUUser to $PUUser"
}

# Match onprem domain user with upn
if ([regex]::Escape($PUUser) -notmatch [regex]::Escape($currentUser)) {
    New-LocalGroup -Name "ADMTEST" | Out-Null
    Add-LocalGroupMember -Group "ADMTEST" -Member "azuread\$PUUser" | Out-Null
    $TranslatedPUUser = (Get-LocalGroupMember -Group "ADMTEST").Name

    ##Write-Host "PU $PUUser is translated to $TranslatedPUUser"

    if ($TranslatedPUUser -eq $currentUser) {
        $PUUser = $TranslatedPUUser
    } else {
        ##Write-Host "ERROR PU UPN not matching CU UPN."
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
if (Test-LocalGroupMember -GroupName "ADMTEST" -UserName $PUUser) {
    #Write-Host "$currentUser is matching with $PUUSer. (Script OK to run)"
    Remove-LocalGroup -Name "ADMTEST" | Out-Null
    Write-Host "OK"
    exit 0
} else {
    #Write-Host "$currentUser is not matching with $PUUSer. (Script NOK to run)"
    Remove-LocalGroup -Name "ADMTEST" | Out-Null
    Write-Host "NOK"
    exit 1
}