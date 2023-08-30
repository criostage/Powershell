Try{
    Switch((Get-WmiObject -Class Win32_ComputerSystem).SystemType){
        { ($_ -match "ARM") }{ Return "ARM" }
        { ($_ -match "PC") }{ Return "Intel" }
        Default { write-host "Unknown System Type" }
    }
    Exit 1
}Catch{
    write-host "Oops, we ran into an issue, please debug me! Error: $_"
    Exit 1
}