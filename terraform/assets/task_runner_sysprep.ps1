# Install ops agent
Write-Host "Installing ops agent.."
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1", "${env:TEMP}\add-google-cloud-ops-agent-repo.ps1")
Invoke-Expression "${env:TEMP}\add-google-cloud-ops-agent-repo.ps1 -AlsoInstall"

# Configure ops agent
Write-Host "Configuring ops agent.."
$OpsAgentConfigPath = Join-Path $env:ProgramFiles "Google\Cloud Operations\Ops Agent\config" 
$OpsAgentConfig = @"
logging:
  receivers:
    windows_event_log:
      type: windows_event_log
      channels: [System, Application, Security, "Microsoft-Windows-TaskScheduler/Operational"]
      receiver_version: 2

"@
New-Item -Path $OpsAgentConfigPath -Name "config.yaml" -ItemType "File" -Value $OpsAgentConfig -Force


# Install scheduled task 'FailureTask'
Write-Host "Installing FailureTask.."

Write-Host "Installing FailureTask scripts.."
$ScriptPath = Join-Path $env:ProgramFiles "ExampleTasks\failure.ps1"
New-Item -ItemType "Directory" -Path (Split-Path $ScriptPath) -Force
New-Item -Path (Split-Path $ScriptPath) -Name (Split-Path $ScriptPath -Leaf) -ItemType "File" -Value "exit 1" -Force


Write-Host "Installing FailureTask scheduled task.."
Import-Module -Name "ScheduledTasks"

$PwshPath = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe" 
$TaskAction = New-ScheduledTaskAction -Execute "`"$PwshPath`"" -Argument "-File `"$ScriptPath`""

$TaskPrincipal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType "ServiceAccount"

$TaskInterval = New-TimeSpan -Minutes 5
$TaskTrigger = New-ScheduledTaskTrigger -Once -At 0am -RepetitionInterval $TaskInterval

$TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances "Queue"

$Task = New-ScheduledTask -Action $TaskAction -Principal $TaskPrincipal -Trigger $TaskTrigger -Settings $TaskSettings
Register-ScheduledTask "FailureTask" -InputObject $Task 
