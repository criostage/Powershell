Param(
    [ValidateRange(25,2500)]
     [INT]$Results = 18,
    [ValidateSet("AU","BR","CA","CH","DE","DK","ES","FI","FR","GB","IE","IR","NO","NL","NZ","TR","US")]
     [ARRAY]$Country = "US",
    [STRING]$DefaultUPN,
    [STRING]$Company,
    [STRING]$TargetOUName
)

Begin{
	function Clear-Username {
		PARAM ([string]$String)
		Return $TextInfo.ToTitleCase([Text.Encoding]::UTF8.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String)))
	}

    $Domain = Get-ADDomain
    $DomainUPNSuffixes = (Get-ADForest).upnsuffixes
    $DomainDN = ($Domain).DistinguishedName
    $DomainNBN = ($Domain).NetBIOSName
    $DomainPDC = ([System.Net.Dns]::GetHostByName(($Domain).PDCEmulator).Hostname)  
    $DomainForest = ($Domain).Forest

    if(-not($DefaultUPN) -and ($DefaultUPN -ne $DomainForest) -or ($DomainUPNSuffixes -notcontains $DefaultUPN)){ $DefaultUPN = $DomainForest }
    if(-not($TargetOUName)){ $TargetOUName = "OU=Users,OU=$DomainNBN,$DomainDN" }
            
    $Departments = @(
        @{"Name"="Finance"; Positions=("Accountant","Data entry")},
        @{"Name"="Human Resources"; Positions=("Coordinator","Officer")},
        @{"Name"="Marketing and Sales"; Positions=("Accountant","Data entry")},
        @{"Name"="Engineering"; Positions=("Engineer","Senior Engineer")},
        @{"Name"="Information Technology"; Positions=("Engineer","Technician")}
    )

    $CountrySettings = @(
        @{"Name"="AU";"C"="AU";"CO"="United States";"CountryCode"="840"},
        @{"Name"="BR";"C"="BR";"CO"="Brazil";"CountryCode"="076"},
        @{"Name"="CA";"C"="CA";"CO"="Canada";"CountryCode"="124"},
        @{"Name"="CH";"C"="CH";"CO"="China";"CountryCode"="156"},
        @{"Name"="DE";"C"="DE";"CO"="Germany";"CountryCode"="276"},
        @{"Name"="DK";"C"="DK";"CO"="Denmark";"CountryCode"="208"},
        @{"Name"="ES";"C"="ES";"CO"="Spain";"CountryCode"="724"},
        @{"Name"="FI";"C"="FI";"CO"="Finland";"CountryCode"="240"},#
        @{"Name"="FR";"C"="FR";"CO"="France";"CountryCode"="250"},
        @{"Name"="GB";"C"="GB";"CO"="United Kingdom";"CountryCode"="826"},
        @{"Name"="IE";"C"="IE";"CO"="Ireland";"CountryCode"="372"},
        @{"Name"="IR";"C"="IR";"CO"="Iran";"CountryCode"="364"},
        @{"Name"="NO";"C"="NO";"CO"="Norway";"CountryCode"="578"},
        @{"Name"="NL";"C"="NL";"CO"="Netherlands ";"CountryCode"="528"},
        @{"Name"="NZ";"C"="NZ";"CO"="New Zealand";"CountryCode"="554"},
        @{"Name"="TR";"C"="TR";"CO"="Turkey";"CountryCode"="792"},
        @{"Name"="US";"C"="US";"CO"="United States";"CountryCode"="840"}
    )
}

Process{
    Try{
        $WebRequestarameters = $null
        $WebRequestarameters += "&nat=$(($Country -join ",").ToLower())"
        $PasswordRequirements = "upper,lower,number,16"
        $UserCountrySettings = $CountrySettings | Where-Object { $_.Name -eq "$Country" }      
        
        $WebRequestURL = "https://randomuser.me/api/?format=PrettyJSON$WebRequestarameters&results=$Results&password=$PasswordRequirements&exc=email,registered,dob&noinfo"
		$WebData = Invoke-WebRequest $WebRequestURL -UseBasicParsing -ContentType "text/plain; charset=utf-8" -OutFile "$env:temp\WebData.json"
        $Webdata = Get-Content -Encoding UTF8 -Raw "$env:temp\WebData.json" | ConvertFrom-Json
        $TextInfo = (Get-Culture).TextInfo

        Foreach($User in $WebData.results ){
            $GivenName = Clear-Username -string $user.name.first
            $Surname = Clear-Username -string $user.name.Last
            $ADUserObj = @{
                'Name' = "$GivenName $Surname"
                'DisplayName' = "$GivenName $Surname"
                'GivenName' = $GivenName
                'Surname' = $Surname
                'StreetAddress' = "$($User.location.street.Number) $($User.location.street.Name)"
                'City' = $TextInfo.ToTitleCase($User.location.city)
                'PostalCode' = $User.location.postcode
                'State' = $TextInfo.ToTitleCase($User.location.state)
                'Country' = $User.Nat
                'Company' = $Company
                'OfficePhone' = $User.phone
                'EmployeeID' = $(Get-Random -Minimum 0 -Maximum 9999).ToString('00000')
                'UserPrincipalName' = "$(("$GivenName.$Surname").Tolower())@$DefaultUPN"
                'SamAccountName' = ("$GivenName.$Surname").Tolower()
                'AccountPassword' = (ConvertTo-SecureString -String "#$($user.login.password)!" -AsPlainText -Force)
                'Enabled' = $True
                'PasswordNeverExpires' = $true
            }
            New-ADUser @ADUserObj -Path $TargetOUName -Server $DomainPDC -ErrorAction SilentlyContinue
            Invoke-WebRequest $User.picture.large -OutFile "$env:TEMP\UserPhoto.jpg"
            Set-ADUser $ADUserObj["SamAccountName"] -Replace @{thumbnailPhoto=([byte[]](Get-Content "$env:TEMP\UserPhoto.jpg" -Encoding byte));C="$($UserCountrySettings.c)";CO="$($UserCountrySettings.co)";CountryCode=$($UserCountrySettings.CountryCode)}
            Start-Sleep -Milliseconds 750
        }

        [System.Collections.ArrayList]$AllUsers = (Get-ADUser -filter "*" -SearchBase $TargetOUName).samaccountname
        
        $CEO = $AllUsers | Get-Random
        Set-ADUser $CEO -Title "Chief Executive Officer" -Department "Board of Directors" -Description "Demo user - Chief Executive Officer"
        $AllUsers.Remove($CEO)

        $i=0
        $Managers = $AllUsers | Get-Random -Count $Departments.Count
        $Managers | foreach-object { Set-ADUser $_ -Title "Manager" -Department $Departments[$i].Name -Manager $CEO -Description "Demo user - $($Departments[$i].Name) Manager"; $i++ }
        $Managers | foreach-object{ $AllUsers.Remove($_) }

        [INT]$DeparmentStaffNumber = [math]::Round($AllUsers.count/$Managers.Count)
        foreach($Manager in $Managers){
            $DepartmentName = (Get-ADUser $Manager -Properties Department).Department
            $Staff = $AllUsers | Get-Random -Count $DeparmentStaffNumber
            $Staff | foreach-object{ Set-ADUser $_ -Manager $Manager -Department $DepartmentName -Description "Demo user - $DepartmentName" -title $($Departments[[Array]::IndexOf($Departments.Name, $DepartmentName)].Item("Positions") | Get-Random -Count 1) }
            $Staff | foreach-object{ $AllUsers.Remove($_) }
        }

        if($AllUsers.Count -gt 0){
            $DepartmentName = "Engineering"
            $DepartmentManager = (Get-ADUser -filter "(Title -like 'Manager') -and (Department -like '$DepartmentName')" -SearchBase $TargetOUName).samaccountname
            foreach($User in $AllUsers){
                Set-ADUser $User -Manager $DepartmentManager -Department $DepartmentName -Description "Demo user - $DepartmentName" -title $($Departments[[Array]::IndexOf($Departments.Name, $DepartmentName)].Item("Positions") | Get-Random -Count 1)
            }            
        }

    }Catch{
        Write-host $_.Exception.Message
    }
}

End{
    Remove-Item -Path "$env:temp\WebData.json"
    Remove-Item -Path "$env:TEMP\UserPhoto.jpg"
}