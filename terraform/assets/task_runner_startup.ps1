# Enable scheduled task history
Write-Host "Enabling Task Scheduler history.."
$TakLog = Get-WinEvent -ListLog "Microsoft-Windows-TaskScheduler/Operational"
$TakLog.IsEnabled = $True
$TakLog.SaveChanges()
