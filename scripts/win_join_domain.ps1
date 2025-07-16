
$domain = "redteam.lab"
$admin = "adminuser"
$password = ConvertTo-SecureString "P@ssw0rd1!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("$domain\$admin", $password)
Add-Computer -DomainName $domain -Credential $cred -Restart

#setup wazuh agent
wazuh_manager="10.0.0.20"

url="https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi"

# download 

.\wazuh-agent-4.12.0-1.msi /q WAZUH_MANAGER=$wazuh_manger

NET START Wazuh


# dns
#
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "10.0.0.10"

