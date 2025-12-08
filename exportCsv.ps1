# this script is used to export csv data of the specified folder
<#
Export-RenameMap.ps1
Creates a CSV mapping of files for manual annotation.

Usage:
  # Create CSV on Desktop (default)
  .\Export-RenameMap.ps1

  # Create CSV for custom folder
  .\Export-RenameMap.ps1 -Folder 'C:\path\to\folder' -OutCsv 'C:\path\map.csv'
#>

param(
    [string]$Folder = 'C:\Users\DELL\OneDrive\Pictures\Screenshots',
    [string]$OutCsv = ([Environment]::GetFolderPath('Desktop') + '\rename_map.csv')
)

if (-not (Test-Path -LiteralPath $Folder)) {
    Write-Error "Folder not found: $Folder"
    exit 1
}

$files = Get-ChildItem -LiteralPath $Folder -File | Sort-Object CreationTime

if ($files.Count -eq 0) {
    Write-Host "No files found in $Folder"
    exit 0
}

$idx = 0
$rows = foreach ($f in $files) {
    $idx++
    [pscustomobject]@{
        Index        = $idx
        OriginalName = $f.Name
        FullPath     = $f.FullName
        CreationTime = $f.CreationTime
        BillNumber   = ''    # <-- fill this column manually
        Notes        = ''    # optional
    }
}

# Export CSV (UTF8)
$rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($rows.Count) rows to: $OutCsv"
Write-Host "Open the CSV in Excel, fill the BillNumber column, save, then run Apply-RenamesFromCsv.ps1"
