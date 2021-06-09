Connect-AzureAD
Connect-ExchangeOnline -ShowProgress $true

$userUPN="DeviceUPN@domain.com"
$alias="SurfaceHub"
$displayName="Country - City - Room 10"
$password="AwsomePasword"
$Location="US"
# Run 'Get-AzureADSubscribedSku | Select SkuPartNumber'
$SubscriptionName="SPE_E3"

#Install-Module -Name ExchangeOnlineManagement
New-Mailbox -MicrosoftOnlineServicesID $userUPN -Alias $alias -Name $displayName -Room -EnableRoomMailboxAccount $true -RoomMailboxPassword (ConvertTo-SecureString -String $password -AsPlainText -Force)

Start-Sleep -Seconds 60

# Get the license Sku ID
$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $SubscriptionName -EQ).SkuID
$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$LicensesToAssign.AddLicenses = $License
    
# Set Location and apply License
Set-AzureADUser -ObjectId $userUPN -UsageLocation $Location
Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $LicensesToAssign