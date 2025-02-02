#Get Join ID
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"
$JoinInfoPath = (Get-ChildItem -Path $regPath).Name
$JoinID = Split-Path $JoinInfoPath -Leaf

#Get Enrolloment UPN
$PUUser = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$JoinID" -Name UserEmail).UserEmail
$currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName

#If on W365 and PUUSer is "fooUser@*" then set PUUser to current user
if (([regex]::Escape($PUUser) -like "fooUser@*") -and ((Get-WmiObject -Class Win32_ComputerSystem).Name -like "CPC*")) {
    $PUUser = $currentUser
}

# Match onprem domain user with upn
if ([regex]::Escape($PUUser) -notmatch [regex]::Escape($currentUser)) {
    New-LocalGroup -Name "ENROLLMENTUSER" | Out-Null
    Add-LocalGroupMember -Group "ENROLLMENTUSER" -Member "$PUUser" | Out-Null
    $TranslatedPUUser = (Get-LocalGroupMember -Group "ENROLLMENTUSER").Name

    if ($TranslatedPUUser -eq $currentUser) {
        $PUUser = $TranslatedPUUser
    } else {
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
if (Test-LocalGroupMember -GroupName "ENROLLMENTUSER" -UserName "$currentUser") {
    Remove-LocalGroup -Name "ENROLLMENTUSER" | Out-Null
    Write-Host "OK"
    exit 0
} else {
    Remove-LocalGroup -Name "ENROLLMENTUSER" | Out-Null
    Write-Host "NOK"
    exit 1
}