<#
.SYNOPSIS
    New-Teacher creates a new teacher account
.DESCRIPTION
    This function will create a new user account and assign it to the approriate OU and Security Groups
.PARAMETER FirstName
.PARAMETER LastName
.PARAMETER DisplayName
.PARAMETER Title
.PARAMETER Location
.PARAMETER Replacing
.PARAMETER StartDate
.PARAMETER EndDate
.PARAMETER EmployeeId
.PARAMETER Smid
.PARAMETER DateOfBirth
.PARAMETER UserName
.PARAMETER Password
.PARAMETER EmailAddress
.PARAMETER IdCardGiven
.PARAMETER IdCardNumber
.PARAMETER VoiceMail
.PARAMETER GenesisGiven
.PARAMETER GenesisStaff
.PARAMETER DeviceGiven
.PARAMETER DeviceAssetTag
.PARAMETER SchoolMessenger
.PARAMETER NJSmart
.PARAMETER SharedDrive
.PARAMETER GoGuardian
.PARAMETER TeacherPage
.PARAMETER CustomOU
.PARAMETER InputObject
.NOTES
.FUNCTIONALITY
#>
function New-Teacher {
    [CmdletBinding(DefaultParameterSetName = "Pipe")]
    Param (
        [Parameter(Mandatory=$false, 
            Position=0,
            ParameterSetName = "Pipe")]
        [string]$FirstName,

        [Parameter(Mandatory=$false, 
            Position=1,
            ParameterSetName = "Pipe")]
        [string]$LastName,

        [Parameter(Mandatory=$false, 
            Position=2,
            ParameterSetName = "Pipe")]
        [string]$DisplayName,

        [Parameter(Mandatory=$false, 
            Position=3,
            ParameterSetName = "Pipe")]
        [string]$Title,

        [Parameter(Mandatory=$false, 
            Position=4,
            ParameterSetName = "Pipe")]
        [string]$Location,

        [Parameter(Mandatory=$false, 
            Position=5,
            ParameterSetName = "Pipe")]
        [string]$Replacing,

        [Parameter(Mandatory=$false, 
            Position=6,
            ParameterSetName = "Pipe")]
        [datetime]$StartDate,

        [Parameter(Mandatory=$false, 
            Position=7,
            ParameterSetName = "Pipe")]
        [datetime]$EndDate,

        [Parameter(Mandatory=$false, 
            Position=8,
            ParameterSetName = "Pipe")]
        [int]$EmployeeId,

        [Parameter(Mandatory=$false, 
            Position=9,
            ParameterSetName = "Pipe")]
        [int]$Smid,

        [Parameter(Mandatory=$false, 
            Position=10,
            ParameterSetName = "Pipe")]
        [datetime]$DateOfBirth,

        [Parameter(Mandatory=$false, 
            Position=11,
            ParameterSetName = "Pipe")]
        [string]$UserName,

        # [Parameter(Mandatory=$false, 
        #     Position=12,
        #     ParameterSetName = "Pipe")]
        # [string]$Password,

        [Parameter(Mandatory=$false, 
            Position=13,
            ParameterSetName = "Pipe")]
        [string]$EmailAddress,

        [Parameter(Mandatory=$false, 
            Position=14,
            ParameterSetName = "Pipe")]
        [string]$IdCardGiven,

        [Parameter(Mandatory=$false, 
            Position=15,
            ParameterSetName = "Pipe")]
        [int]$IDCardNumber,

        [Parameter(Mandatory=$false, 
            Position=16,
            ParameterSetName = "Pipe")]
        [int]$VoiceMail,

        [Parameter(Mandatory=$false, 
            Position=17,
            ParameterSetName = "Pipe")]
        [string]$GenesisGiven,

        [Parameter(Mandatory=$false, 
            Position=18,
            ParameterSetName = "Pipe")]
        [string]$GenesisStaff,

        [Parameter(Mandatory=$false, 
            Position=19,
            ParameterSetName = "Pipe")]
        [string]$DeviceGiven,

        [Parameter(Mandatory=$false, 
            Position=20,
            ParameterSetName = "Pipe")]
        [string]$DeviceAssetTag,

        [Parameter(Mandatory=$false, 
            Position=21,
            ParameterSetName = "Pipe")]
        [string]$SchoolMessenger,

        [Parameter(Mandatory=$false, 
            Position=22,
            ParameterSetName = "Pipe")]
        [string]$NJSmart,

        [Parameter(Mandatory=$false, 
            Position=23,
            ParameterSetName = "Pipe")]
        [string]$SharedDrive,

        [Parameter(Mandatory=$false, 
            Position=24,
            ParameterSetName = "Pipe")]
        [switch]$GoGuardian,

        [Parameter(Mandatory=$false, 
            Position=25,
            ParameterSetName = "Pipe")]
        [string]$TeacherPage,

        [Parameter(Mandatory=$false, 
            Position=26,
            ParameterSetName = "Pipe")]
        [string]$CustomOU,

        [Parameter(Mandatory=$false,
            ParameterSetName = "ImportCsv",
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Input a CSV/Array with at least the following cols: FirstName, LastName")]
        [array]$InputObject
    )

    begin {
        # Set the $DisplayName if none was given
        if ($null -eq $DisplayName) {
            $DisplayName = $LastName.Replace($LastName[0],$LastName[0].ToString().ToUpper()) `
                + ', ' + $FirstName.Replace($FirstName[0],$FirstName[0].ToString().ToUpper())
        }

        # Set the $UserName if none was given
        if ($null -eq $UserName) {
            $UserName = ($FirstName[0] + $LastName).ToLower()
        }

        # Set the $StartDate to today if none was given
        if ($null -eq $StartDate) {
            $StartDate = (Get-Date -Format "MM/dd/yyyy")
        }

        # Set the email address if none was given
        if ($null -eq $EmailAddress) {
            $EmailAddress = ('{0}@westex.org' -f $UserName)
        }

        $user = [User]::new('dc01')
        $DateRegex = "([0][1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])[- /.](19|20)[0-9]{2}"
        Write-Verbose -Message "Creating new teacher user account now."
    }

    process {
        if ($null -ne $InputObject) {
            $InputObject | ForEach-Object {
                if (($_."First Name" -eq '') -or ($_."Last Name" -eq '')) {
                    # At the very least, we need a first and last name, if either of those are blank, 
                    #assume the row is blank and continue
                    continue
                }

                $user.FirstName = $_."First Name"
                $user.LastName = $_."Last Name"
                $user.Name = $_."Name"
                $user.DisplayName = $_."Name"
                $user.Title = $_."Title"
                $user.Location = $_."Location"
                $user.Replacing = $_."Replacing"

                if ($_."Start Date" -match $DateRegex) {
                    $user.SetStartDate($_."Start Date")
                }

                if ($_."End Date" -match $DateRegex) {
                    $user.SetEndDate($_."End Date")
                }

                $user.EmployeeId = $_."Employee ID"
                $user.UserName = $UserName
                # $user.PlainPassword = $Password
                $user.EmailAddress = $_."Email Address"
                $user.UserPrincipalName = $_."Email Address"
                $user.HomePage = $_."ID Card #"
                if ($_."Voice Mail" -match '\d') {
                    $user.PhoneExtension = [int]$_."Voice Mail"
                }

                if ((-not ([string]::IsNullOrWhiteSpace($CustomOU)))) { 
                    $user.SetUserOU($CustomOU)
                } else {
                    $user.SetUserOU('OU=Teachers,OU=Accounts,DC=WESTEX,DC=ORG')
                }

                $user.DomainName = 'westex.org'
            }
        } else {
            $user.FirstName = $FirstName
            $user.LastName = $LastName
            $user.Name = ('{0}, {1}' -f $LastName, $FirstName)
            $user.DisplayName = $DisplayName
            $user.Title = $Title
            $user.Location = $Location
            $user.Replacing = $Replacing
            
            if ($StartDate -match $DateRegex) {
                $user.SetStartDate($StartDate)
            }

            if ($EndDate -match $DateRegex) {
                $user.SetEndDate($EndDate)
            }

            $user.EmployeeId = $EmployeeId
            $user.UserName = $UserName
            $user.PlainPassword = $Password
            $user.EmailAddress = $EmailAddress
            $user.UserPrincipalName = $UserPrincipalName
            $user.HomePage = $IDCardNumber

            if ($VoiceMail -match "\d") {
                $user.PhoneExtension = $VoiceMail
            }

            if ((-not ([string]::IsNullOrWhiteSpace($CustomOU)))) { 
                $user.SetUserOU($CustomOU)
            } else {
                $user.SetUserOU('OU=Teachers,OU=Accounts,DC=WESTEX,DC=ORG')
            }

            $user.DomainName = 'westex.org'
        }

        $user.Save($True) #$False for testing

        Write-Verbose -Message "New teacher added."
    }

 }
