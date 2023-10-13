<#
 #  User object
 #
 #  Author: Anthony Rizzo
 #  Created date: 10/3/2023
 #>

class User {
    #region class properties
    [string]$DomainController
    [string]$DomainName
    [bool]$ForceSave
    [string]$FirstName
    [string]$LastName
    [string]$DisplayName
    [string]$Title
    [string]$Location
    [string]$Replacing
    [datetime]$StartDate = (Get-Date -Format "MM/dd/yyyy")
    [datetime]$EndDate
    [string]$EmployeeId
    [string]$Department = ''
    [string]$UserName
    [string]$PlainPassword
    [string]$PlainPasswordPrefix = 'changeme'
    [securestring]$SecurePassword
    [string]$EmailAddress
    [string]$IdCardNumber
    [string]$UserOU
    [int]$PhoneExtension
    [bool]$UserCannotChangePassword = $False
    [bool]$ChangePasswordAtNextLogon = $True
    [string]$Description
    [bool]$Enabled = $True
    [string]$Name
    [string]$UserPrincipalName
    [string]$Initials
    [string]$Company
    [string]$Manager
    [string]$HomePage
    #For Process Messages
    [bool]$UserExists
    [bool]$Committed = $False
    [bool]$SessionDomainJoined
    #endregion

    #region class constructors
    User() {
        if ((Get-cimintance win32_computersystem).partofdomain -ne $True) {
            $this.SessionDomainJoined = $False
            Write-Host 'This session is not joined to an Active Directory domain, please pass the name of a domain controller as the first parameter. ([User]::new("dc"))'
            return
        }

        $this.DomainController = $env:LOGONSERVER.TrimStart("\\")
    }

    User([string]$dc) {
        if ((Get-cimintance win32_computersystem).partofdomain -ne $True) {
            $this.SessionDomainJoined = $False
        }

        $this.DomainController = $dc
    }

    User([string]$dc, [string]$domainName) {
        if ((Get-cimintance win32_computersystem).partofdomain -ne $True) {
            $this.SessionDomainJoined = $False
        }
        
        $this.DomainController = $dc
        $this.DomainName = $domainName
    }
    #endregion

    #region class methods
    [void]SetStartDate([string]$Date) {
        $this.StartDate = [datetime]("$Date").ToString()
    }

    [void]SetEndDate([string]$Date) {
        $this.EndDate = [datetime]("$Date").ToString()
    }

    [void]SetDisplayName() {
        if ((-not ([string]::IsNullOrEmpty($this.DisplayName))) -or (-not ([string]::IsNullOrWhiteSpace($this.DisplayName)))) {
            # $DisplayName was already provided
            Write-Host ('Display name has already been provided, using: {0}' -f $this.DisplayName)
            return
        }

        if (($null -eq $this.FirstName) -or ($null -eq $this.LastName)) {
            Write-Error 'Either the first or last name were not set.'
        }
        else {
            $this.DisplayName = ('{0}, {1}' -f $this.LastName, $this.FirstName)
            Write-Host ('Display name will use Last Name, First Name, using: {0}' -f $this.DisplayName)
        }
    }

    [void]SetName() {
        if ((-not ([string]::IsNullOrEmpty($this.Name))) -or (-not ([string]::IsNullOrWhiteSpace($this.Name)))) {
            $this.Name = $this.DisplayName
            Write-Host ('Setting Name to: {0}' -f $this.Name)
        }
        else {
            Write-Host ('Name has already been provided, using: {0}' -f $this.Name)
        }
    }

    [void]SetHomePage([string]$url, [bool]$tls) {
        # Nothing for now, will format a URL string later
    }

    [void]SetUserPrincipalName() {
        if ((-not ([string]::IsNullOrEmpty($this.UserPrincipalName))) -or (-not ([string]::IsNullOrWhiteSpace($this.UserPrincipalName)))) {
            Write-Host ('User principal name was provided: {0}' -f $this.UserPrincipalName)
        }
        else {
            $upn = ('{0}@{1}' -f $this.UserName, $this.DomainName)
            $this.UserPrincipalName = $upn
            Write-Host ('Setting User principal name to: {0}' -f $upn)
        }
    }

    [void]SetDescription() {
        if ((-not ([string]::IsNullOrEmpty($this.Description))) -or (-not ([string]::IsNullOrWhiteSpace($this.Description)))) {
            Write-Host ('Description already provided: {0}' -f $this.Description)
        }
        else {
            $desc = ('{0} - {1}' -f $this.Location, $this.Title)
            if (($null -ne $this.Replacing) -and ($this.Replacing -ne '')) {
                $desc = $desc + (' (Replacing {0})' -f $this.Replacing)
            }

            $this.Description = $desc
            Write-Host ('Setting description to: {0}' -f $desc)
        }

    }

    [void]SetEmailAddress() {
        if ((-not ([string]::IsNullOrEmpty($this.EmailAddress))) -or (-not [string]::IsNullOrWhiteSpace($this.EmailAddress))) {
            Write-Host ('Email address was provided: {0}' -f $this.EmailAddress)
        }
        else {
            $email = ('{0}@{1}' -f $this.UserName, $this.DomainName)
            Write-Host ('Setting email address to: {0}' -f $email)
            $this.EmailAddress = $email
        }
    }

    [void]GenerateSecurePassword() {
        if ((-not ([string]::IsNullOrEmpty($this.PlainPassword))) -or (-not ([string]::IsNullOrWhiteSpace($this.PlainPassword)))) {
            Write-Host ('Password has already been provided. Using: {0}' -f $this.PlainPassword)
        }
        else {
            $currentYear = Get-Date -Format yyyy
            $this.PlainPassword = $this.PlainPasswordPrefix + $currentYear
        }

        $this.SecurePassword = ConvertTo-SecureString $this.PlainPassword -AsPlainText -Force
        Write-Host ('Password is: {0}' -f $this.PlainPassword)
    }

    [void]SetUserName() {
        if ((-not ([string]::IsNullOrEmpty($this.UserName))) -or (-not ([string]::IsNullOrWhiteSpace($this.UserName)))) {
            Write-Host ('Username has already been provided. Using: {0}' -f $this.UserName)
        }
        else {
            $this.UserName = $this.FirstName.ToLower()[0] + $this.LastName.ToLower()
            Write-Host "No username was provided, using " $this.UserName
        }
    }

    [void]SetInitials() {
        $this.Initials = $this.FirstName.ToUpper()[0] + $this.LastName.ToUpper()[0]
        Write-Host ('Setting initials to: {0}' -f $this.Initials)
    }

    [void]SetUserOU([string]$OU) {
        Write-Host ('Setting user OU to: {0}' -f $OU)
        $this.UserOU = $OU
    }

    # Check if username exists in local database
    [bool]Exists() {
        if ($null -ne (Get-ADUser -Filter "sAMAccountName -eq '$($this.UserName)'" -Server $this.DomainController)) {
            return $True
        }

        return $False
    }

    # Save the current record into local database
    # $Commit When $False will only stage the properties for the record and check if the account exists.
    [void]Save([bool]$Commit) {
        $this.UserExists = $False
        $this.SetDisplayName()
        $this.SetUserName()
        # todo: Maybe this shouldn't be set by default?
        $this.SetName()
        $this.SetEmailAddress()
        $this.SetUserPrincipalName()
        $this.GenerateSecurePassword()
        $this.SetInitials()
        $this.SetDescription()

        # Make sure the users OU Path was specified
        # todo: Let it default?
        if ($null -eq $this.UserOU) {
            Write-Host "UserOU cannot be empty. Please specify with .SetUserOU() in format 'OU=Accounts,DC=Domain,DC=COM'."
            return
        }

        # Check if an account with the same sAMAccountName already exists
        # todo: This might be over complicating it as opposed to if (.UserExists -and !.ForceSave), will have to look back when program is further along in development
        Write-Host 'Now checking if user account already exists...'
        if ($True -eq $this.UserExists) {
            $this.Exists = $True
            if ($False -eq $this.ForceSave) {
                Write-Host 'User already exists and you are not forcing changes, no changes will be made.'
                return
            }
        }
        else {
            if ($True -eq $this.Exists()) {
                $this.UserExists = $True

                if ($False -eq $this.ForceSave) {
                    Write-Host 'User already exists and you are not forcing changes, no changes will be made.'
                    return
                }
            }
            else {
                Write-Host 'User does not exist, it will be created.'
            }
        }

        if ($True -eq $Commit) {
            $this.Commit()
        }
        else {
            Write-Host 'You are not committing changes.'
        }
    }

    [void]Commit() {
        Write-Host "You are now commiting changes to ActiveDirectory."
        try {
            $Splat = @{
                AccountPassword = $this.SecurePassword
                CannotChangePassword = $this.UserCannotChangePassword
                Description = $this.Description
                ChangePasswordAtLogon = $this.ChangePasswordAtNextLogon
                Department = $this.Department
                DisplayName = $this.DisplayName
                EmailAddress = $this.EmailAddress
                EmployeeNumber = $this.EmployeeId
                Enabled = $this.Enabled
                GivenName = $this.FirstName
                Surname = $this.LastName
                Initials = $this.FirstName.ToUpper()[0] + $this.LastName.ToUpper()[0]
                SamAccountName = $this.UserName
                OfficePhone = $this.PhoneExtension
                Office = $this.Location
                Path = $this.UserOU
                Title = $this.Title
                UserPrincipalName = $this.EmailAddress
                Server = $this.DomainController
                Name = $this.Name
                Company = $this.Company
                Manager = $this.Manager
                HomePage = $this.HomePage
            }

            if ($this.EndDate -gt $this.StartDate) {
                $Splat.AccountExpirationDate = $this.EndDate
            }

            if ($False -eq $this.UserExists) {
                Write-Host 'Adding user to Active Directory.'
                New-ADUser @Splat -ErrorAction Stop
            } else {
                Write-Host 'Updating user.'
                Set-ADUser @Splat -ErrorAction Stop
            }
        }
        catch [Microsoft.ActiveDirectory.Management.ADException] {
            Switch ($_.Exception.Message) {
                default { Write-Host "Unhandled ADException: $_" }
            }
            return
        }
        catch {
            Write-Host "Unhandled exception: $_"
            return
        }

        $this.Committed = $True
        if ($this.SessionDomainJoined -eq $False) {
            Write-Host 'You are not on a Domain joined device, you might have to perform addition actions to sync the user account.'
        }
    }

    # If $force is $True when .Save is called, this will update the existing record with given properties
    [void]UpdateRecord() {
        return
    }

    [string]WhoAmI() {
        return $($env:USERNAME)
    }

    [string]ToString() {
        return ('{0} | {1} | {2}' -f $this.DisplayName, $this.UserName, $this.PlainPassword)
    }

    [Microsoft.ActiveDirectory.Management.ADAccount]GetCreatedUser() {
        return (Get-ADUser $this.UserName -Properties * -Server $this.DomainController -ErrorAction Stop)
    }
    #endregion
}
