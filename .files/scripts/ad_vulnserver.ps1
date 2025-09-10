 #Pre-create AD computer object for vulnserver


$computerName = "vuln"
$ou = "OU=VulnMachines,DC=redteam,DC=lab"

New-ADComputer -Name $computerName -SamAccountName $computerName -Path $ou

