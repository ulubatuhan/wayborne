<# : Wayborne kurulum ve baslatici (Windows). Bu dosyayi indirip cift tikla.
@echo off
set "WB_HOME=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText('%~f0'))"
if errorlevel 1 pause
exit /b
#>
# Ilk calismada: Git yoksa kurar, depoyu bu dosyanin yanindaki Wayborne\ klasorune indirir, Godot 4.2.2'yi
# indirir, projeyi ice aktarir ve oyunu acar. Sonraki calismalarda: GitHub'daki Wayborne dalina bakar, yeni
# surum varsa indirir, gerekiyorsa yeniden ice aktarir ve oyunu acar. Her oynayista bunu calistir.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Repo   = 'https://github.com/ulubatuhan/wayborne'
$Branch = 'Wayborne'
$GodotV = '4.2.2-stable'
$Home_  = Join-Path $env:WB_HOME 'Wayborne'
$Game   = Join-Path $Home_ 'oyun'
$Tools  = Join-Path $Home_ 'godot'
$Gui    = Join-Path $Tools "Godot_v${GodotV}_win64.exe"
$Cli    = Join-Path $Tools "Godot_v${GodotV}_win64_console.exe"
$Log    = Join-Path $Home_ 'son_ice_aktarma.log'

function Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }

function Ensure-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) { return }
    Step 'Git bulunamadi, kuruluyor (winget)'
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements | Out-Host
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User') + ';C:\Program Files\Git\cmd'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git kurulamadi. https://git-scm.com/download/win adresinden kurup bu dosyayi yeniden calistir.'
    }
}

# Sig klon (--depth 1): tum gecmis ~600 MB, oynamak icin yalnizca son surum gerekir.
function Sync-Game {
    if (-not (Test-Path (Join-Path $Game '.git'))) {
        Step 'Oyun indiriliyor (ilk sefer, birkac dakika surebilir)'
        git clone --depth 1 --branch $Branch $Repo $Game
        if ($LASTEXITCODE) { throw 'Depo indirilemedi (GitHub girisi istenirse tarayicidan onayla).' }
        return $true
    }
    Step 'GitHub''da yeni surum var mi bakiliyor'
    git -C $Game fetch --depth 1 origin $Branch
    if ($LASTEXITCODE) { Write-Host 'Baglanti yok; eldeki surumle aciliyor.' -ForegroundColor Yellow; return $false }
    $local = git -C $Game rev-parse HEAD
    $remote = git -C $Game rev-parse FETCH_HEAD
    if ($local -eq $remote) { Write-Host 'Oyun guncel.'; return $false }
    # oyun\ yalnizca oynamak icin; ice aktarmanin dokundugu dosyalar dahil her sey GitHub'daki haline doner.
    Step 'Yeni surum indiriliyor'
    git -C $Game reset --hard FETCH_HEAD | Out-Host
    return $true
}

function Ensure-Godot {
    if (Test-Path $Cli) { return }
    Step "Godot $GodotV indiriliyor"
    New-Item -ItemType Directory -Force $Tools | Out-Null
    $zip = Join-Path $Tools 'godot.zip'
    Invoke-WebRequest "https://github.com/godotengine/godot/releases/download/$GodotV/Godot_v${GodotV}_win64.exe.zip" -OutFile $zip
    Expand-Archive $zip -DestinationPath $Tools -Force
    Remove-Item $zip
}

# Atlas degisikliklerinden sonra ice aktarma iki kez gerekir (README, Local Testing).
function Import-Game {
    Step 'Oyun ice aktariliyor (ilk sefer uzun surer, dokular ~1,2 GB)'
    # Windows PowerShell 5.1 yonlendirilen stderr'i hata kaydina cevirir; Stop'ta bu bir istisna olurdu.
    $ErrorActionPreference = 'Continue'
    1..2 | ForEach-Object { & $Cli --headless --path $Game --import *> $Log }
    Write-Host "Ice aktarma bitti (gunluk: $Log)"
}

try {
    New-Item -ItemType Directory -Force $Home_ | Out-Null
    Ensure-Git
    $updated = Sync-Game
    Ensure-Godot
    if ($updated -or -not (Test-Path (Join-Path $Game '.godot'))) { Import-Game }
    Step 'Wayborne aciliyor'
    Start-Process $Gui -ArgumentList '--path', "`"$Game`""
} catch {
    Write-Host "`nHATA: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
