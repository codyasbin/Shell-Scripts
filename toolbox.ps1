<#
useful-toolbox-patched.ps1
Patched and cleaned version of the Useful PowerShell Toolbox.
Changes made:
- Fixed invalid variable interpolation inside double-quoted strings ("... $_") by using formatted strings or named parameters.
- Ensured Write-Log calls in catch blocks won't trigger parser errors.
- Kept original behavior, prompts and logging intact.
Author: ChatGPT (patched for you)
#>

# -------------------- Helpers --------------------
function Ensure-Admin {
    if (-not ([bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Write-Warning "Not running as Administrator. Some actions (restore point, certain disk ops) may require admin rights."
        Write-Host "You can re-run PowerShell as Administrator to enable all features."
    }
}

function Timestamp { (Get-Date).ToString("yyyyMMdd_HHmmss") }

function Write-Log {
    param($Message, $Level = "INFO")
    $logLine = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    $global:LogBuffer += $logLine + [Environment]::NewLine
    Write-Host $logLine
}

function Save-Log {
    $logDir = "$([Environment]::GetFolderPath('Desktop'))\PS-Toolbox-Logs"
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
    $file = "$logDir\log_$(Timestamp).txt"
    $global:LogBuffer | Out-File -FilePath $file -Encoding UTF8
    Write-Host "Saved log to: $file"
}

# Prepare global log buffer
$global:LogBuffer = @()

# -------------------- System Report --------------------
function Generate-SystemReport {
    Write-Log "Generating system report..."
    $desktop = [Environment]::GetFolderPath('Desktop')
    $ts = Timestamp
    $outTxt = "$desktop\SystemReport_$ts.txt"
    $outCsv = "$desktop\SystemReport_$ts.csv"

    $info = [ordered]@{}
    $info.ComputerName = $env:COMPUTERNAME
    $info.User = $env:USERNAME
    $info.OS = (Get-CimInstance Win32_OperatingSystem).Caption
    $info.OSVersion = (Get-CimInstance Win32_OperatingSystem).Version
    $info.LastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $info.CPU = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
    $info.Cores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
    $info.LogicalProcessors = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
    $mem = Get-CimInstance Win32_ComputerSystem
    $info.TotalPhysicalMB = [math]::Round($mem.TotalPhysicalMemory / 1MB,2)
    $logicalDisks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select DeviceID, @{n='FreeMB';e={[math]::Round($_.FreeSpace/1MB,2)}}, @{n='SizeMB';e={[math]::Round($_.Size/1MB,2)}}
    $net = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } | Select-Object -Property Description, IPAddress

    # Write text report
    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("SYSTEM REPORT - $ts") | Out-Null
    $sb.AppendLine("========================================") | Out-Null
    foreach ($k in $info.Keys) { $sb.AppendLine("{0,-20} : {1}" -f $k, $info[$k]) | Out-Null }
    $sb.AppendLine("") | Out-Null
    $sb.AppendLine("Logical Disks:") | Out-Null
    foreach ($d in $logicalDisks) {
        $sb.AppendLine("  {0} - Free: {1} MB / Size: {2} MB" -f $d.DeviceID, $d.FreeMB, $d.SizeMB) | Out-Null
    }
    $sb.AppendLine("") | Out-Null
    $sb.AppendLine("Network Interfaces:") | Out-Null
    foreach ($n in $net) {
        $ips = ($n.IPAddress -join ", ")
        $sb.AppendLine("  {0} - {1}" -f $n.Description, $ips) | Out-Null
    }
    $sb.ToString() | Out-File -FilePath $outTxt -Encoding UTF8

    # Write a compact CSV for quick parsing (disks as separate rows)
    $rows = @()
    foreach ($d in $logicalDisks) {
        $rows += [pscustomobject]@{
            Timestamp = $ts
            Computer = $info.ComputerName
            Drive = $d.DeviceID
            FreeMB = $d.FreeMB
            SizeMB = $d.SizeMB
        }
    }
    $rows | Export-Csv -Path $outCsv -NoTypeInformation -Encoding UTF8

    Write-Log "System report saved to: $outTxt and $outCsv"
    Write-Host ""
}

# -------------------- Clean Temp & Recycle Bin --------------------
function Clean-TempsAndRecycle {
    Write-Log "Estimating temp file size..."
    $tempPaths = @(
        "$env:LOCALAPPDATA\Temp",
        "$env:windir\Temp"
    ) | Where-Object { Test-Path $_ }
    $total = 0
    foreach ($p in $tempPaths) {
        $size = (Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
        if ($size) { $total += $size }
    }
    $totalMB = [math]::Round($total/1MB,2)
    Write-Host "Estimated temp files size: $totalMB MB"
    $recycleEstimate = "(Recycle Bin cleanup will free space depending on items inside.)"
    Write-Host $recycleEstimate

    if (-not (Read-Host "Proceed to delete temp files AND empty Recycle Bin? (Y/N)").ToUpper().StartsWith("Y")) {
        Write-Log "User canceled cleanup."
        return
    }

    foreach ($p in $tempPaths) {
        try {
            Write-Log "Deleting files in $p ..."
            Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        } catch {
            # Use formatted string to avoid parser issues with $_ inside double quotes
            Write-Log -Message ("Failed to fully clean {0}: {1}" -f $p, $_) -Level "WARN"
        }
    }

    # Clear Recycle Bin (PowerShell 5+)
    try {
        Write-Log "Emptying Recycle Bin..."
        Clear-RecycleBin -Force -ErrorAction Stop
    } catch {
        Write-Log -Message ("Clear-RecycleBin failed or not available: {0}" -f $_) -Level "WARN"
    }
    Write-Log "Cleanup complete."
}

# -------------------- Backup Documents --------------------
function Backup-Documents {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $source = [Environment]::GetFolderPath('MyDocuments')
    if (-not (Test-Path $source)) { Write-Log "Documents folder not found at $source" "ERROR"; return }
    $destDir = "$desktop\Backups"
    if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory | Out-Null }
    $archive = "$destDir\DocsBackup_$(Timestamp).zip"
    Write-Log "Creating backup archive: $archive"
    try {
        Compress-Archive -Path "$source\*" -DestinationPath $archive -Force -ErrorAction Stop
        Write-Log "Backup completed: $archive"
    } catch {
        Write-Log -Message ("Backup failed: {0}" -f $_) -Level "ERROR"
    }
}

# -------------------- Disk & SMART-ish Summary --------------------
function Show-DiskSummary {
    Write-Log "Gathering disk & SMART-ish info..."
    # Logical disk usage
    $ld = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,2)}}, @{n='SizeGB';e={[math]::Round($_.Size/1GB,2)}}
    Write-Host "Logical Disks:"
    $ld | Format-Table -AutoSize

    # Physical drives + basic SMART using WMI root\wmi if available
    try {
        $drives = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction Stop
        if ($drives) {
            Write-Host "`nSMART (failure-predict) status available:"
            foreach ($d in $drives) {
                $inst = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictData -Filter "InstanceName='$($d.InstanceName)'" -ErrorAction SilentlyContinue
                $model = ($d.InstanceName -split '\|')[0]
                $status = if ($d.PredictFailure -eq $true) { "FAIL" } else { "OK" }
                Write-Host ("  {0,-30} -> PredictFailure: {1}" -f $model, $status)
            }
        } else {
            Write-Host "SMART info not available via WMI on this machine."
        }
    } catch {
        Write-Host "SMART query failed or not supported on this system (requires WMI providers)." -ForegroundColor Yellow
    }
}

# -------------------- Create System Restore Point --------------------
function Create-RestorePoint {
    # Only works if System Restore is enabled and OS supports Checkpoint-Computer
    if (-not (Get-Command Checkpoint-Computer -ErrorAction SilentlyContinue)) {
        Write-Log "Checkpoint-Computer cmdlet not available on this system." "WARN"
        return
    }
    if (-not (Read-Host "Create a restore point now? (Y/N)").ToUpper().StartsWith("Y")) {
        Write-Log "User skipped restore point creation."
        return
    }
    try {
        Write-Log "Creating restore point..."
        Checkpoint-Computer -Description "PS-Toolbox RestorePoint $(Timestamp)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log "Restore point created successfully."
    } catch {
        Write-Log -Message ("Failed to create restore point: {0}" -f $_) -Level "ERROR"
    }
}

# -------------------- Menu --------------------
function Show-Menu {
    Clear-Host
    Write-Host "========================================"
    Write-Host " PowerShell Useful Toolbox"
    Write-Host " (Run as Admin for full capabilities)"
    Write-Host "========================================"
    Write-Host "1) Generate System Report (txt + csv on Desktop)"
    Write-Host "2) Clean Temp folders + Empty Recycle Bin"
    Write-Host "3) Backup Documents to ZIP (Desktop\Backups)"
    Write-Host "4) Show Disk & SMART-ish Summary"
    Write-Host "5) Create System Restore Point (if supported)"
    Write-Host "6) Run ALL (report -> cleanup -> backup -> disk summary) *CAREFUL*"
    Write-Host "0) Exit"
}

# -------------------- Main --------------------
Ensure-Admin
while ($true) {
    Show-Menu
    $choice = Read-Host "Select an option"
    switch ($choice) {
        "1" { Generate-SystemReport }
        "2" { Clean-TempsAndRecycle }
        "3" { Backup-Documents }
        "4" { Show-DiskSummary }
        "5" { Create-RestorePoint }
        "6" {
            Write-Log "User chose FULL RUN"
            Generate-SystemReport
            Clean-TempsAndRecycle
            Backup-Documents
            Show-DiskSummary
            if ((Read-Host "Create a restore point as part of FULL RUN? (Y/N)").ToUpper().StartsWith("Y")) { Create-RestorePoint }
            Write-Log "FULL RUN complete"
        }
        "0" {
            Write-Log "User exited."
            Save-Log
            break
        }
        default {
            Write-Host "Invalid choice. Try again."
        }
    }
    Write-Host ""
    Read-Host "Press Enter to return to menu..."
}

# End of script
