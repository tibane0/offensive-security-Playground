# Windows Server AD DC Setup


# set static ip

# Configuration
$InterfaceAlias = "Ethernet"          # Change if needed (e.g., "Ethernet0", "Ethernet 2")
$IPAddress      = "10.0.0.10"
$PrefixLength   = 24                  # For subnet mask 255.255.255.0
$Gateway        = "10.0.0.1"
$DNSServers     = @("10.0.0.10", "8.8.8.8")  # First is the DC (itself), second external for fallback

# Set static IP
New-NetIPAddress -InterfaceAlias $InterfaceAlias `
                 -IPAddress $IPAddress `
                 -PrefixLength $PrefixLength `
                 -DefaultGateway $Gateway

# Set DNS servers
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias `
                           -ServerAddresses $DNSServers

# Optional: Confirm changes
Get-NetIPAddress -InterfaceAlias $InterfaceAlias
Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias


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
