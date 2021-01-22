Param(
    [Parameter(Mandatory=$false)][INT]$BackupsToRetain = 30,
    [Parameter(Mandatory=$false)][STRING]$ConfigFileSrcDirectory = "/cf/conf/backup/",
    [Parameter(Mandatory=$true)][STRING]$BackupDestDirectory,
    [Parameter(Mandatory=$true)][STRING]$ComputerName,
    [Parameter(Mandatory=$true)][STRING]$Username = "admin",
    [Parameter(Mandatory=$false)][STRING]$Password,
    [Parameter(Mandatory=$false)][SWITCH]$firstrun
)

[Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime] | Out-Null
$VaultObj = New-Object Windows.Security.Credentials.PasswordVault 
$CredObj = New-Object windows.Security.Credentials.PasswordCredential
[STRING]$ConfigFileFormat = ".xml"

switch($firstrun){
    True { 
        if(!(Get-Module -Name Posh-SSH)){ Install-Module -Name Posh-SSH }
        $CredObj.Resource = $ComputerName
        $CredObj.UserName = $Username
        $CredObj.Password = $Password
        $VaultObj.Add($CredObj)
        Remove-Variable CredObj
    }
    False {
        [String]$Username = ($VaultObj.RetrieveAll() | Where-Object {$_.Resource -eq "$ComputerName"} | Select-Object -First 1).UserName
        if($Username){
            [SecureString]$Password = ConvertTo-SecureString -String (($VaultObj.Retrieve("$ComputerName",$UserName)) | Select-Object -First 1).Password -AsPlainText -Force
            [PSCredential]$Credencial = [PSCredential]::new($Username, $Password)
            New-SFTPSession -ComputerName $ComputerName -Credential $Credencial -Verbose -AcceptKey
            if( (Get-SFTPSession).connected -eq $true ){
                $ConfigFiles = Get-SFTPChildItem -SessionId 0 -Path $ConfigFileSrcDirectory | Where-Object {$_.FullName -like "*$ConfigFileFormat"} | Sort-Object LastWriteTime | Select-Object -Last 1
                foreach ($File in $ConfigFiles){ Get-SFTPFile -SessionId 0 -RemoteFile $File.FullName -LocalPath $BackupDestDirectory -Verbose -Overwrite }
                Remove-SFTPSession -SessionId 0 -Verbose

                Get-ChildItem -Path $BackupDestDirectory -Filter "*$ConfigFileFormat" | Sort-Object -Descending LastWriteTime | Select-Object -Skip $BackupsToRetain | Remove-Item -Verbose
            }
        }else{
            Write-Host "Credential not found in Vault. Use -firstrun and -password flags to register."
        }
    }
}