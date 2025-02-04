#Get Join ID
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"
$JoinInfoPath = (Get-ChildItem -Path $regPath).Name
$JoinID = Split-Path $JoinInfoPath -Leaf
Write-Host "Join ID: $JoinID"

#Get Enrolloment UPN
$PUUser = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$JoinID" -Name UserEmail).UserEmail
$currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName

#If on W365 and PUUSer is "fooUser@*" then set PUUser to current user
if (([regex]::Escape($PUUser) -like "fooUser@*") -and ((Get-WmiObject -Class Win32_ComputerSystem).Name -like "CPC*")) {
    Write-Host "Running on W365. PUUser cannot match. Setting PUUser to current user."
    $PUUser = $currentUser
}

# Match onprem domain user with upn
if ([regex]::Escape($PUUser) -notmatch [regex]::Escape($currentUser)) {
    New-LocalGroup -Name ADMTEST | Out-Null
    Add-LocalGroupMember -Group "ADMTEST" -Member "azuread\$PUUser" | Out-Null
    $TranslatedPUUser = (Get-LocalGroupMember -Group "ADMTEST").Name
    Remove-LocalGroup -Name "ADMTEST"

    Write-Host "$PUUser is translated to $TranslatedPUUser"

    if ($TranslatedPUUser -eq $currentUser) {
        $PUUser = $TranslatedPUUser
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
if (Test-LocalGroupMember -GroupName "Administrators" -UserName $PUUser) {
    Write-Host "$PUUser is in Administrators group"
    exit 0
} else {
    Write-Host "ERROR. $PUUser is not in Administrators group"
    exit 1
}