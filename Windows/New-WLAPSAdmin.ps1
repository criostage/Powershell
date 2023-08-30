# Loading built-in System.Web.Security.Membership
Add-Type -AssemblyName System.Web

# Define Password Criteria
[INT]$PasswordLength = 128
[INT]$PasswordAmountOfNonAlphanumeric = [math]::Round($PasswordLength/4)

# Define Windows LAPS Administrator Account details into a Powershell Hash Table
$LocalAdminParams = @{
    Name = "localmgr"
    Description = "Local Manager Account"
    Password = $(ConvertTo-SecureString $([System.Web.Security.Membership]::GeneratePassword($PasswordLength,$PasswordAmountOfNonAlphanumeric)) -AsPlainText -force)
    AccountNeverExpires = $true
}

# Execute
Try{
    # Test if the the account already exists. 
    if(Get-LocalUser -Name $LocalAdminParams.name -ErrorAction SilentlyContinue){
        # If was previously created, the script will return the exitcode 0 (sucess); 
        write-host """$($LocalAdminParams.name)"" account already exists on this device. Skipping..." 
    }else{
        # else if doesn't exist then create the account and add it to the Local Administrator Group.
        write-host """$($LocalAdminParams.name)"" account doesn't exist on this device. Creating account..."
        New-LocalUser @LocalAdminParams | Out-null
        write-host "Adding ""$($LocalAdminParams.name)"" account to the local Administrators Group"
        Add-LocalGroupMember -Group "Administrators" -Member $LocalAdminParams.name
    }
    write-host "Script ran sucessefully, exiting with code 0."
    Exit 0
}Catch{
    # In the case something goes wrong with the account creation, throw's an error and exit with code 1 (failure)
    write-host "Oops, we ran into an issue, please debug me! Error: $_"
    $errMsg = $_.Exception.Message
    return $errMsg
    Exit 1
}