# BackupFolder.ps1
# This script copies all files from a source folder to a backup destination with timestamp.

# Source and destination paths
$sourceFolder = "C:\Users\DELL\OneDrive\Pictures\stutis"
$backupRoot = "C:\Users\DELL\OneDrive\Pictures\"

# Create backup folder with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupFolder = Join-Path $backupRoot "Backup_$timestamp"
New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

Write-Host "Backing up files from $sourceFolder to $backupFolder" -ForegroundColor Cyan

# Copy files
Copy-Item -Path "$sourceFolder\*" -Destination $backupFolder -Recurse -Force

Write-Host "Backup completed successfully!" -ForegroundColor Green
