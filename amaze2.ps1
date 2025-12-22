Clear-Host

# ===============================
# Terminal Awakening
# ===============================

$ErrorActionPreference = "SilentlyContinue"

function TypeWriter {
    param (
        [string]$Text,
        [int]$Delay = 35,
        [ConsoleColor]$Color = "Gray"
    )
    $oldColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host
    $Host.UI.RawUI.ForegroundColor = $oldColor
}

function Glitch {
    $chars = "!@#$%^&*()_+=-{}[]<>?/|\"
    for ($i=0; $i -lt 30; $i++) {
        Write-Host ($chars | Get-Random -Count 20 -Join "") -ForegroundColor Red
        Start-Sleep -Milliseconds 25
    }
}

TypeWriter "Initializing consciousness..." 40 Cyan
Start-Sleep 1

TypeWriter "Accessing kernel memory..." 35 DarkCyan
Start-Sleep 1

TypeWriter "Reading user intent..." 35 Yellow
Start-Sleep 1

Glitch

TypeWriter "WARNING: SYSTEM AWARENESS INCREASING" 30 Red
Start-Sleep 1

# Fake system scan
for ($i = 0; $i -le 100; $i += (Get-Random -Minimum 3 -Maximum 8)) {
    Write-Progress -Activity "Scanning reality layers" `
        -Status "$i% complete" `
        -PercentComplete $i
    Start-Sleep -Milliseconds (Get-Random -Minimum 80 -Maximum 180)
}

Write-Progress -Activity "Scanning reality layers" -Completed

Start-Sleep 1

# Fake secrets
$secrets = @(
    "Your curiosity is your strongest weapon.",
    "You already know more than you think.",
    "Systems fear those who question them.",
    "Control is an illusion maintained by silence.",
    "Not all cages have bars."
)

TypeWriter "Decrypting hidden truths..." 40 Magenta
Start-Sleep 1

foreach ($secret in $secrets) {
    TypeWriter ">> $secret" 30 Green
    Start-Sleep 0.8
}

Start-Sleep 1

# Final message
TypeWriter "" 1
TypeWriter "SYSTEM MESSAGE:" 30 Cyan
TypeWriter "You are not running the terminal." 40 White
TypeWriter "The terminal is responding to you." 40 White

Start-Sleep 1

TypeWriter "" 1
TypeWriter "Awakening complete." 45 Yellow
TypeWriter "Exit when ready." 60 DarkGray
TypeWriter "" 1
# End of script
