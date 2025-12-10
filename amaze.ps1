# amaze.ps1
# An "amazing" PowerShell console demo: Matrix rain, CPU/RAM dashboard, ASCII reveal, fireworks, melody.
# Safe: read-only, purely visual & informational.
# Author: ChatGPT (custom for you)
# Usage: Save as amaze.ps1 and run in Windows PowerShell

# -------------------------
# Helper: write colored text centered
function Write-Centered {
    param($text, $fg = 'White', $bg = $null)
    $w = [console]::WindowWidth
    $pad = [math]::Max(0, ([int](($w - $text.Length) / 2)))
    if ($bg) { Write-Host (' ' * $pad) -NoNewline -ForegroundColor $fg -BackgroundColor $bg }
    Write-Host (' ' * $pad) -NoNewline -ForegroundColor $fg
    if ($bg) { Write-Host $text -ForegroundColor $fg -BackgroundColor $bg }
    else { Write-Host $text -ForegroundColor $fg }
}

# -------------------------
# Matrix rain effect (animated)
function Start-MatrixRain {
    param($durationSec = 6)
    $w = [console]::WindowWidth
    $h = [console]::WindowHeight
    $cols = 1..($w-1) | ForEach-Object { @{pos=$_; len = Get-Random -Minimum 3 -Maximum ($h/2); tail = "" } }
    $end = (Get-Date).AddSeconds($durationSec)
    Clear-Host
    while ((Get-Date) -lt $end) {
        foreach ($c in $cols) {
            if (Get-Random -Maximum 100 -lt 7) { $c.len = Get-Random -Minimum 3 -Maximum ($h/2) }
            $s = -join ((1..$c.len) | ForEach-Object { [char](Get-Random -Minimum 33 -Maximum 126) })
            [console]::SetCursorPosition([math]::Min($c.pos, [console]::BufferWidth-1), (Get-Random -Minimum 0 -Maximum ([console]::WindowHeight - 1)))
            Write-Host $s -NoNewline -ForegroundColor Green
        }
        Start-Sleep -Milliseconds 65
    }
    Clear-Host
}

# -------------------------
# Animated progress bar with status
function Show-ProgressBar {
    param($text = "Loading...", $seconds = 4)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $width = [console]::WindowWidth - 20
    while ($sw.Elapsed.TotalSeconds -lt $seconds) {
        $pct = $sw.Elapsed.TotalSeconds / $seconds
        $filled = [int]([math]::Round($width * $pct))
        $bar = ('=' * $filled) + (' ' * ($width - $filled))
        $line = ("{0,-12} [{1}] {2,3}%" -f $text, $bar, [int]($pct*100))
        Write-Host $line -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 120
        [console]::SetCursorPosition(0, [console]::CursorTop)
    }
    Write-Host ""  # newline
}

# -------------------------
# Small CPU & Memory gauge (reads once)
function Show-SystemStats {
    $cpu = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $mem = Get-CimInstance -ClassName Win32_OperatingSystem
    $total = [math]::Round($mem.TotalVisibleMemorySize / 1KB,1)
    $free = [math]::Round($mem.FreePhysicalMemory / 1KB,1)
    $used = [math]::Round($total - $free,1)
    Write-Centered "=== SYSTEM SNAPSHOT ===" Yellow
    Write-Host ""
    Write-Host ("CPU Usage:    {0,5}%" -f $cpu) -ForegroundColor Magenta
    Write-Host ("Memory Used:  {0,6} MB / {1,6} MB" -f $used, $total) -ForegroundColor Magenta
    Write-Host ""
}

# -------------------------
# ASCII art reveal animation
function Show-AsciiReveal {
    $lines = @(
"    ___    __  __    __    ___   ___   ___ ",
"   / _ \  / / / /   / /   /   | /   | /   |",
"  / /_\ \/ /_/ /   / /   / /| |/ /| |/ /| |",
" /  _  / __  /   / /___/ ___ / ___ / ___ / ",
"/_/ |_/_/ /_/   /_____/ /  |_/_/  |_/_/  |_|",
"                                            ",
"            A M A Z E - P S 1               "
    )
    $top = [int](([console]::WindowHeight - $lines.Count) / 2)
    $left = [int](([console]::WindowWidth - ($lines | Measure-Object -Maximum Length).Maximum) / 2)
    for ($i=0; $i -lt $lines.Count; $i++) {
        [console]::SetCursorPosition($left, $top + $i)
        for ($j=0; $j -lt $lines[$i].Length; $j++) {
            $ch = $lines[$i][$j]
            $c = Get-Random -Minimum 1 -Maximum 15
            $color = [System.Enum]::GetValues([ConsoleColor])[$c]
            Write-Host -NoNewline $ch -ForegroundColor $color
            Start-Sleep -Milliseconds (Get-Random -Minimum 3 -Maximum 18)
        }
        Write-Host ""
    }
    Write-Host ""
}

# -------------------------
# Fireworks: bursts of colored characters near center
function Show-Fireworks {
    param($bursts = 10)
    $cx = [int]([console]::WindowWidth / 2)
    $cy = [int]([console]::WindowHeight / 2)
    for ($b=0; $b -lt $bursts; $b++) {
        $count = Get-Random -Minimum 12 -Maximum 30
        $color = (Get-Random -Minimum 1 -Maximum 15)
        for ($p=0; $p -lt $count; $p++) {
            $angle = (Get-Random -Minimum 0 -Maximum 628) / 100.0
            $dist = [math]::Sqrt((Get-Random)) * (Get-Random -Minimum 4 -Maximum ([console]::WindowWidth/6))
            $x = [int]($cx + $dist * [math]::Cos($angle))
            $y = [int]($cy + $dist * [math]::Sin($angle))
            if ($x -ge 0 -and $x -lt [console]::BufferWidth -and $y -ge 0 -and $y -lt [console]::WindowHeight) {
                [console]::SetCursorPosition($x, $y)
                Write-Host "*" -NoNewline -ForegroundColor ([System.Enum]::GetValues([ConsoleColor])[$color])
            }
        }
        Start-Sleep -Milliseconds 280
        Clear-Host
    }
}

# -------------------------
# Mini melody using Console.Beep (Windows)
function Invoke-Melody {
    # Only works on Windows where Console.Beep exists
    $notes = @( 440, 494, 523, 659, 587, 523, 440 )  # A B C E D C A
    foreach ($n in $notes) {
        try { [console]::Beep($n,120) } catch { }
        Start-Sleep -Milliseconds 80
    }
}

# -------------------------
# MAIN ROUTINE
Clear-Host
Write-Centered "Namaste hajur - prepare to be amazed!" Cyan
Start-Sleep -Milliseconds 800

# 1) Start with subtle matrix rain
Start-MatrixRain -durationSec 4

# 2) Smooth progress bar
Show-ProgressBar -text "Warming up" -seconds 3

# 3) Show ASCII reveal
Show-AsciiReveal
Start-Sleep -Milliseconds 1000

# 4) CPU / Memory snapshot
Show-SystemStats
Start-Sleep -Milliseconds 1200

# 5) Play a short tune while fireworks burst
Start-Job -ScriptBlock { Invoke-Melody } | Out-Null
Show-Fireworks -bursts 8

# Clean up background job
Get-Job | Remove-Job -Force

# Final message
Write-Host ""
Write-Centered "Amazing demo complete! Dhanyabad!" Green
Write-Host ""