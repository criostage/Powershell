New-VMSwitch -SwitchName "vNATInternalSwitch" -SwitchType Internal
New-NetIPAddress -IPAddress 192.168.2.1 -PrefixLength 24 -InterfaceIndex (Get-NetIPInterface | Where-Object { ($_.InterfaceAlias -match "vNATInternalSwitch") -and ($_.AddressFamily -eq "IPv4") }).ifIndex
New-NetNat -Name "vNat" -InternalIPInterfaceAddressPrefix 192.168.2.0/24