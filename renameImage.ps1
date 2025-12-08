param(
    [string]$Folder = 'C:\Users\DELL\OneDrive\Pictures\Camera Roll',
    [switch]$Apply
)

function Abort([string]$msg) {
    Write-Host "`nERROR: $msg`n" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $Folder)) {
    Abort "Folder not found: $Folder"
}

# Get files sorted by CreationTime (earliest first)
$files = Get-ChildItem -LiteralPath $Folder -File | Sort-Object CreationTime

if ($files.Count -eq 0) {
    Write-Host "No files found in $Folder" -ForegroundColor Yellow
    exit 0
}

# ====== FIX: compute mode string first ======
$modeString = if ($Apply) { "APPLY (will rename)" } else { "DRY RUN (preview only)" }

Write-Host "Folder: $Folder"
Write-Host "Files found: $($files.Count)"
Write-Host "Mode: $modeString"
Write-Host ''

# Build mapping: Original -> TempGUID -> FinalName (Image N.ext)
$map = [System.Collections.Generic.List[psobject]]::new()
$idx = 0
foreach ($f in $files) {
    $idx++
    $guid = [guid]::NewGuid().ToString()
    $temp = Join-Path $Folder ("__tmp_" + $guid + $f.Extension)
    $final = Join-Path $Folder ("CameraImage {0}{1}" -f $idx, $f.Extension)
    $map.Add([pscustomobject]@{
        Index = $idx
        Original = $f.FullName
        OriginalName = $f.Name
        CreationTime = $f.CreationTime
        TempPath = $temp
        FinalPath = $final
        Extension = $f.Extension
    })
}

# Preview
Write-Host "Preview (earliest creation => Image 1):" -ForegroundColor Cyan
foreach ($m in $map) {
    Write-Host (" {0,3}  {1,-40}  ->  {2}" -f $m.Index, $m.OriginalName, (Split-Path $m.FinalPath -Leaf))
}
Write-Host ''

if (-not $Apply) {
    Write-Host "DRY RUN: No files changed. To apply, re-run with the -Apply switch." -ForegroundColor Yellow
    exit 0
}

# APPLY MODE: perform two-pass rename
Write-Host "Applying renames..." -ForegroundColor Green

# 1) originals -> temp
foreach ($m in $map) {
    try {
        Move-Item -LiteralPath $m.Original -Destination $m.TempPath -ErrorAction Stop
        Write-Host ("TEMP: {0} -> {1}" -f $m.OriginalName, (Split-Path $m.TempPath -Leaf))
    } catch {
        Write-Host ("FAILED temp rename: {0}  -- {1}" -f $m.OriginalName, $_.Exception.Message) -ForegroundColor Red
        Abort "Aborting to avoid partial state. You may need to manually revert temporary files."
    }
}

# 2) temp -> final (sort by CreationTime to be safe)
$mapSorted = $map | Sort-Object CreationTime, Index
foreach ($m in $mapSorted) {
    try {
        Move-Item -LiteralPath $m.TempPath -Destination $m.FinalPath -ErrorAction Stop
        Write-Host ("FINAL: {0} -> {1}" -f (Split-Path $m.TempPath -Leaf), (Split-Path $m.FinalPath -Leaf))
    } catch {
        Write-Host ("FAILED final rename: {0}  -- {1}" -f (Split-Path $m.TempPath -Leaf), $_.Exception.Message) -ForegroundColor Red
        Abort "Aborting. Some files may still be temporary names. Please check folder and revert if needed."
    }
}

Write-Host ''
Write-Host ("Done. Renamed {0} file(s)." -f $map.Count) -ForegroundColor Green
