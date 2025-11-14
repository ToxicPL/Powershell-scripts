$list = Get-Content -Path "LIST.txt"

foreach ($machine in $list) {
    $ping = Test-NetConnection -ComputerName $machine -InformationLevel Quiet
    if ($ping) {
        Write-Output "$machine is reachable"
    } else {
        Write-Output "$machine is not reachable" 
    }
}