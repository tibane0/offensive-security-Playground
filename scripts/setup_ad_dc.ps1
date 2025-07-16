# Windows Server AD DC Setup

# Variables
$DomainName = "redteam.lab"
$NetbiosName = "REDTEAM"
$SafeModePwd = ConvertTo-SecureString "pass" -AsPlainText -Force

# Install AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to DC
Install-ADDSForest -DomainName $DomainName `
                  -DomainNetbiosName $NetbiosName `
                  -SafeModeAdministratorPassword $SafeModePwd `
                  -InstallDNS -Force

############################################
# Create AD Users and Groups

# Users to create
$Users = @(
    @{Name="admin"; Password="pass"; Group="Domain Admins"},
    @{Name="dev"; Password="dev123!"; Group="Domain Users"},
    @{Name="vr"; Password="vr123!"; Group="Domain Users"},
    @{Name="intern"; Password="intern123!"; Group="Domain Users"}
)

foreach ($user in $Users) {
    $securePwd = ConvertTo-SecureString $user.Password -AsPlainText -Force
    New-ADUser -Name $user.Name -SamAccountName $user.Name -AccountPassword $securePwd -Enabled $true
    Add-ADGroupMember -Identity $user.Group -Members $user.Name
}

#stop sconfig from launching
Set-SConfig -AutoLaunch $false
