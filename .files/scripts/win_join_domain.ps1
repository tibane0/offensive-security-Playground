$domain = "redteam.lab"
$admin = "admin"  # Domain admin account
$adminPassword = "P@ssw0rd1!"  # Replace with your actual password
$ouPath = "OU=Servers,DC=redteam,DC=lab"  # Optional

# Convert to secure credential
$password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("$domain\$admin", $password)

# Verify domain connectivity
if (-not (Test-Connection -ComputerName $domain -Count 2 -Quiet)) {
    Write-Error "Domain $domain is unreachable. Check DNS and network settings."
    exit
}

# Verify credentials
try {
    $null = Get-ADUser -Identity $admin -Credential $cred -ErrorAction Stop
} catch {
    Write-Error "Invalid credentials or user '$admin' does not exist in $domain."
    exit
}

# Join domain
try {
    if ($ouPath) {
        Add-Computer -DomainName $domain -Credential $cred -OUPath $ouPath -Restart -ErrorAction Stop
    } else {
        Add-Computer -DomainName $domain -Credential $cred -Restart -ErrorAction Stop
    }
    Write-Host "Successfully joined $domain. Restarting..." -ForegroundColor Green
} catch {
    Write-Error "Failed to join domain: $_"
}


#setup wazuh agent
wazuh_manager="10.0.0.20"

url="https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi"

# download 
wget -Uri=$url -Outfile="wazuh-agent-4.12.0-1.msi"

.\wazuh-agent-4.12.0-1.msi /q WAZUH_MANAGER=$wazuh_manger
#WAZUH_REGISTRATION_SERVER=$wazuh_manager
NET START Wazuh

# dns
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "10.0.0.10"

