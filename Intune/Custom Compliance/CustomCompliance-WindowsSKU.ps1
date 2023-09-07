$WindowsSKU = Get-WindowsEdition -Online
$ComplianceResults = @{ WindowsSKU = $WindowsSKU.Edition }
return $ComplianceResults | ConvertTo-Json -Compress