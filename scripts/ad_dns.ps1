# Define DNS zone and records
$zone = "redteam.lab"

$hosts = @(
    @{Name="win"; IP="10.0.0.20"},
    @{Name="linux"; IP="10.0.0.30"},
    @{Name="vuln"; IP="10.0.0.50"},
    @{Name="monitor"; IP="10.0.0.40"},
    @{Name="test"; IP="10.0.0.60"}
)



foreach ($host in $hosts) {
    Add-DnsServerResourceRecordA -ZoneName $zone -Name $host.Name -IPv4Address $host.IP -TimeToLive 01:00:00
}

# reverse lookup zone
Add-DnsServerPrimaryZone -NetworkId "10.0.0.0/24" -ReplicationScope "Domain"


