function Test-LocalGroupMember {
    param (
        [string]$GroupName,
        [string]$UserName
    )

    $groupMembers = Get-LocalGroupMember -Group $GroupName
    foreach ($member in $groupMembers) {
        #$memberSid = (New-Object System.Security.Principal.NTAccount($member.Name)).Translate([System.Security.Principal.SecurityIdentifier]).Value | Out-Null
        if ($member.Name -eq $UserName) {
            return $true
        }
    }
    return $false
}

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

#Validate
if (Test-LocalGroupMember -GroupName $adminGroup -UserName $currentUser) {
    Write-Host "$currentUser ($currentUserSid) is in $adminGroup group."
    exit 0
} else {
    Write-Host "$currentUser ($currentUserSid) is not in $adminGroup group."
    exit 1
}