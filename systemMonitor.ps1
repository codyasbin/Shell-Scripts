# SystemMonitor.ps1
# This script logs CPU and Memory usage every 10 seconds to a log file.

# Log file location
$logFile = "$env:USERPROFILE\Desktop\SystemUsageLog.txt"

Write-Host "Monitoring system performance..." -ForegroundColor Cyan
Write-Host "Logs will be saved to: $logFile" -ForegroundColor Green

# Add header if file doesn't exist
if (-not (Test-Path $logFile)) {
    "Timestamp, CPU (%), Memory Used (MB)" | Out-File $logFile
}

# Infinite loop to log every 10 seconds
while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $mem = [math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize/1KB - `
                         (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1KB, 2)
    
    "$timestamp, $cpu, $mem" | Out-File $logFile -Append
    
    Start-Sleep -Seconds 10
}
