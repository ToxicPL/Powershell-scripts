# Versions: 
# 0.1 - Prepare basic data excluding ram (This will be add further)
#
# Hostname, OS version, Uptime, CPU and Ram usage, Drive list with free space
$hostname = $env:COMPUTERNAME
$cpu = (Get-WmiObject win32_processor).Name
$os = (Get-CimInstance Win32_OperatingSystem)
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
#$ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$disks = (Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{Name="Total Size (GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="FreeSpace (GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}})


#$raport = "Hostname: $hostname `nCPU Name: $cpu `nSystem Caption: " + $os.Caption + " `nOS Version: " + $os.Version + " `nUptime: $uptime "
#$raport | Format-List