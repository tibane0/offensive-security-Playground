# Windows Server AD DC Setup


# set static ip

# Configuration
$InterfaceAlias = "Ethernet" 
$IPAddress      = "10.0.0.10"
$PrefixLength   = 24                  # For subnet mask 255.255.255.0
$Gateway        = "10.0.0.1"
#$DNSServers     = @("10.0.0.10", "8.8.8.8")  # First is the DC (itself), second external for fallback
$DNSServers = "8.8.8.8"

# Verify network interface exists
if (-not (Get-NetAdapter -Name $InterfaceAlias -ErrorAction SilentlyContinue)) {
    Write-Error "Network interface $InterfaceAlias not found!"
    exit
}

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

$password_len = 16
$chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
$password = -join ((1..$password_len) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })

# Variables
$DomainName = "redteam.lab"
$NetbiosName = "REDTEAM"
$SafeModePwd = ConvertTo-SecureString $password -AsPlainText -Force

# Install AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to DC
Install-ADDSForest -DomainName $DomainName `
                  -DomainNetbiosName $NetbiosName `
                  -SafeModeAdministratorPassword $SafeModePwd `
                  -InstallDNS -Force


#stop sconfig from launching
Set-SConfig -AutoLaunch $false


