<#
 #  AD User Groups
 #
 #  Author: Anthony Rizzo
 #  Created date: 10/3/2023
 #>

Import-Module ActiveDirectory

class UserGroup {
    #region class properties
    [string]$GroupName
    [string]$DomainController
    [string]$GroupOU
    [Microsoft.ActiveDirectory.Management.ADAccount]$UserAccountObject
    [Microsoft.ActiveDirectory.Management.ADPrincipal]$GroupAccountObject
    #endregion

    #region class constructors
    UserGroup() {
        if ((Get-CimInstance win32_computersystem).partofdomain -ne $True) {
            Write-Host 'This session is not joined to an Active Directory domain, please pass the name of a domain controller as the first parameter. ([UserGroup]::new("dc"))'
            return
        }

        $this.DomainController = $env:LOGONSERVER.TrimStart("\\")
    }

    UserGroup([string]$dc) {
        $this.DomainController = $dc
    }
    #endregion

    #region class methods
    [void]GroupExists() {
        try {
            Write-Host ('Checking if group exists, {0}.' -f $this.GroupName)
            $Group = Get-ADGroup -Identity $this.GroupName -Server $this.DomainController -ErrorAction Stop
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Host ('Provided group does not exist: {0}' -f $this.GroupName)
            return
        }

        $this.GroupAccountObject = $Group
    }

    # Add Member to group
    [void]AddUserToGroup() {
        $this.GroupExists()
        try {
            Write-Host ('Attempting to add user to group, ({0}, {1})' -f $this.UserAccountObject.SamAccountName, $this.GroupName)
            Add-ADGroupMember -Identity $this.GroupAccountObject -Members $this.UserAccountObject -Server $this.DomainController
        }
        catch [Microsoft.ActiveDirectory.Management.ADException] {
            Write-Host "Unhandled ADException: $_"
            return
        }

        Write-Host ('Successfully added user, {0}, to group, {1}.' -f $this.UserAccountObject.SamAccountName, $this.GroupName)
    }
    #endregion
}