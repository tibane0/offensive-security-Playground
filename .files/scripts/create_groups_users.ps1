# Define AD groups and departments
$adGroups = @(
    @{ Name = "Executives"; Department = "Executives" },
    @{ Name = "Red Team Level Blue"; Department = "Red Team" },
    @{ Name = "Red Team Level Red"; Department = "Red Team" },
    @{ Name = "Vulnerability Research Level Blue"; Department = "Vulnerability Research" },
    @{ Name = "Vulnerability Research Level Red"; Department = "Vulnerability Research" },
    @{ Name = "Exploit Development Level Blue"; Department = "Exploit Development" },
    @{ Name = "Exploit Development Level Red"; Department = "Exploit Development" },
    @{ Name = "Blue Team"; Department = "Blue Team" }
)

# Base OUs
$baseOU = "OU=Red Team Labs Staff,DC=redteam,DC=lab"
$groupOU = "OU=SecurityGroups,DC=redteam,DC=lab"

# Create AD groups (if they don't exist)
foreach ($group in $adGroups) {
    if (-not (Get-ADGroup -Filter { Name -eq $group.Name } -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $group.Name -GroupScope Global -Path $groupOU -Description "$($group.Department) department group with $($group.Name) clearance"
    }
}

# Users to create
$Users = @(
    @{ FirstName = "George"; LastName = "Winsley"; JobTitle = "Manager"; Department = "Executives"; Group = "Executives" },
    @{ FirstName = "James"; LastName = "Smith"; JobTitle = "Exploit Developer"; Department = "Exploit Development"; Group = "Exploit Development Level Blue" },
    @{ FirstName = "John"; LastName = "Trevor"; JobTitle = "Lead Exploit Developer"; Department = "Exploit Development"; Group = "Exploit Development Level Red" },
    @{ FirstName = "Lisa"; LastName = "Ronaldo"; JobTitle = "Vulnerability Researcher"; Department = "Vulnerability Research"; Group = "Vulnerability Research Level Blue" },
    @{ FirstName = "Mike"; LastName = "Gordon"; JobTitle = "Senior Vulnerability Researcher"; Department = "Vulnerability Research"; Group = "Vulnerability Research Level Red" },
    @{ FirstName = "Henry"; LastName = "Smith"; JobTitle = "Red Team Operator"; Department = "Red Team"; Group = "Red Team Level Blue" },
    @{ FirstName = "Patrick"; LastName = "Oswell"; JobTitle = "Senior Red Team Engineer"; Department = "Red Team"; Group = "Red Team Level Red" },
    @{ FirstName = "Albert"; LastName = "Winsley"; JobTitle = "Senior Security Engineer"; Department = "Blue Team"; Group = "Blue Team" }
)

# Create users and assign groups
$createdUsers = @()
$passwords = @{}  # Store passwords for output

foreach ($user in $Users) {
    $firstName = $user.FirstName
    $lastName = $user.LastName
    $userName = "$($firstName.ToLower()).$($lastName.ToLower())"
    $email = "$userName@redteam.lab"
    $group = $user.Group

    # Generate random password
    $password = -join ((48..57 + 65..90 + 97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

    # Create user
    New-ADUser `
        -Name "$firstName $lastName" `
        -GivenName $firstName `
        -Surname $lastName `
        -SamAccountName $userName `
        -UserPrincipalName "$userName@redteam.lab" `
        -EmailAddress $email `
        -Title $user.JobTitle `
        -Department $user.Department `
        -AccountPassword $securePassword `
        -Path $baseOU `
        -Enabled $true `
        -ChangePasswordAtLogon $false  # Disable forced password change

    # Add to group
    Add-ADGroupMember -Identity $group -Members $userName

    # Store password for output
    $passwords[$userName] = $password

    # Set manager (skip for first user)
    if ($createdUsers.Count -gt 0) {
        $manager = $createdUsers[-1]
        Set-ADUser -Identity $userName -Manager $manager
    }

    $createdUsers += $userName
}

# Output passwords (for lab use)
$passwords.GetEnumerator() | ForEach-Object {
    Write-Host "User: $($_.Key) | Password: $($_.Value)" -ForegroundColor Cyan
}

Write-Host "Users and groups created successfully!" -ForegroundColor Green