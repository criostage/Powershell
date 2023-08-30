try {
    if ( (Get-AppxPackage "*Teams*" -AllUsers -ErrorAction SilentlyContinue).Name -eq "MicrosoftTeams" ){
        Write-Host "Built-in Teams Chat App Detected"
        Exit 1
    }else{
        Write-Host "Built-in Teams Chat App Not Detected"
        Exit  0
    }
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    Exit 1
}