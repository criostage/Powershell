Try{
    $Service = Get-Service -name "Audiosrv"
    if(($Service.Status -ne "Stopped") -or ($Service.StartType -ne "Disabled")){
        $Service | Stop-Service -PassThru | Set-Service -StartupType Disabled
    }
    write-host "Script ran sucessefully, exiting with code 0."
    Exit 0
}Catch{
    write-host "Oops, we ran into an issue, please debug me! Error: $_"
    Exit 1
}
