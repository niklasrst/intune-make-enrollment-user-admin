#Get Join ID
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo"
$JoinInfoPath = (Get-ChildItem -Path $regPath).Name
$JoinID = Split-Path $JoinInfoPath -Leaf

#Get Enrolloment UPN and SID translation handling for W365
$PUUser = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$JoinID" -Name UserEmail).UserEmail
$PUUserSid = ""
if ([regex]::Escape($PUUser) -like "fooUser@*") {
    $PUUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName
    if ($PUUser -like "FRA\*") {
        $PUUser = $PUUser.Substring(4)
    } else {
        $PUUser = $PUUser -replace '^.*\\', ''
    }
    $PUUserSid = (New-Object System.Security.Principal.NTAccount("FRA\$PUUser")).Translate([System.Security.Principal.SecurityIdentifier]).Value
} else {
    $PUUserSid = (New-Object System.Security.Principal.NTAccount("azuread\$PUUser")).Translate([System.Security.Principal.SecurityIdentifier]).Value
}
$currentUser = (Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique).UserName
$currentUserSid = (New-Object System.Security.Principal.NTAccount($currentUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

if ($currentUserSid -eq $PUUserSid) {
    #Write-Host "$currentUser ($currentUserSid) is matching with $PUUSer ($PUUserSid). (Script OK to run)"
    Write-Host "OK"
    exit 0
} else {
    #Write-Host "$currentUser ($currentUserSid) is not matching with $PUUSer ($PUUserSid). (Script NOK to run)"
    Write-Host "NOK"
    exit 1
}