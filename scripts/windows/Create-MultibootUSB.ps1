<#
.SYNOPSIS
    Prépare une clé USB multiboot (Windows/Linux/macOS*) basée sur Ventoy,
    avec un menu GRUB2 personnalisé.

    * macOS : support expérimental non couvert par ce script, voir docs/MACOS.md

.PARAMETER DiskNumber
    Numéro du disque cible (voir Get-Disk). REQUIS.

.PARAMETER Gpt
    Utilise le partitionnement GPT (défaut : MBR côté Ventoy).

.PARAMETER SecureBoot
    Active le support Secure Boot de Ventoy.

.PARAMETER SkipVentoyInstall
    Ne (ré)installe pas Ventoy ; met seulement à jour le contenu/la config.

.PARAMETER WindowsIso
    Chemin vers un ISO Windows que vous avez obtenu légalement (copié tel quel).
    Facultatif : vous pouvez aussi glisser-déposer vos ISO vous-même dans les
    dossiers créés sur la clé (ISOs\Windows, ISOs\Linux\Ubuntu, ISOs\Linux\Kali,
    ISOs\macOS).

.PARAMETER MacosImage
    Chemin vers une image macOS (.img) — voir docs/MACOS.md (expérimental).

.PARAMETER Yes
    Ne pas demander confirmation (dangereux).

.EXAMPLE
    .\Create-MultibootUSB.ps1 -DiskNumber 1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][int]$DiskNumber,
    [switch]$Gpt,
    [switch]$SecureBoot,
    [switch]$SkipVentoyInstall,
    [string]$WindowsIso,
    [string]$MacosImage,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$WorkDir = Join-Path $env:TEMP ("usb-multiboot-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WorkDir | Out-Null

function Write-Info  { param($m) Write-Host "[*] $m" -ForegroundColor Cyan }
function Write-Ok    { param($m) Write-Host "[+] $m" -ForegroundColor Green }
function Write-Warn2 { param($m) Write-Host "[!] $m" -ForegroundColor Yellow }
function Fail        { param($m) Write-Host "[x] $m" -ForegroundColor Red; Cleanup; exit 1 }

function Cleanup {
    if (Test-Path $WorkDir) { Remove-Item -Recurse -Force $WorkDir -ErrorAction SilentlyContinue }
}

trap {
    Write-Host "[x] Erreur : $($_.Exception.Message)" -ForegroundColor Red
    Cleanup
    exit 1
}

# --- Vérification des droits administrateur ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Fail "Ce script doit être exécuté dans un PowerShell 'Administrateur'."
}

# --- Résolution et vérification du disque cible ---
$disk = Get-Disk -Number $DiskNumber -ErrorAction SilentlyContinue
if (-not $disk) { Fail "Disque numéro $DiskNumber introuvable. Utilisez Get-Disk pour lister les disques." }
if ($disk.IsBoot -or $disk.IsSystem) {
    Fail "REFUS : le disque $DiskNumber est marqué comme disque système/boot. Arrêt par sécurité."
}

Write-Warn2 "Le disque suivant va être ENTIÈREMENT EFFACÉ :"
Get-Disk -Number $DiskNumber | Format-Table -AutoSize | Out-Host
Get-Partition -DiskNumber $DiskNumber -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-Host

if (-not $Yes) {
    $reply = Read-Host "Tapez exactement 'oui' pour continuer"
    if ($reply -ne "oui") { Fail "Confirmation refusée, arrêt." }
}

# --- Étape 1 : (ré)installation de Ventoy ---
if (-not $SkipVentoyInstall) {
    Write-Info "Récupération de la dernière version de Ventoy…"
    $releaseJson = Invoke-RestMethod -Uri "https://api.github.com/repos/ventoy/Ventoy/releases/latest"
    $asset = $releaseJson.assets | Where-Object { $_.browser_download_url -match "windows\.zip$" } | Select-Object -First 1
    if (-not $asset) { Fail "Impossible de trouver l'archive Ventoy Windows dans la release GitHub." }

    $zipPath = Join-Path $WorkDir "ventoy-windows.zip"
    Write-Info "Téléchargement : $($asset.browser_download_url)"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

    Write-Info "Extraction de Ventoy…"
    Expand-Archive -Path $zipPath -DestinationPath $WorkDir -Force
    $ventoyDir = Get-ChildItem -Path $WorkDir -Directory | Where-Object { $_.Name -like "ventoy-*" } | Select-Object -First 1
    if (-not $ventoyDir) { Fail "Extraction de Ventoy échouée." }
    $ventoyExe = Join-Path $ventoyDir.FullName "Ventoy2Disk.exe"

    # Ventoy2Disk.exe expose un mode CLI silencieux (VTOYCLI) depuis les versions
    # récentes. S'il n'est pas disponible (anciennes versions), on bascule sur le
    # mode graphique et on attend que l'utilisateur termine manuellement.
    $cliArgs = @("VTOYCLI", "/I", "/Disk:$DiskNumber")
    if ($Gpt) { $cliArgs += "/GPT" }
    if ($SecureBoot) { $cliArgs += "/SecureBoot" }

    Write-Info "Tentative d'installation silencieuse de Ventoy (CLI)…"
    $proc = Start-Process -FilePath $ventoyExe -ArgumentList $cliArgs -PassThru -Wait -WindowStyle Hidden
    if ($proc.ExitCode -ne 0) {
        Write-Warn2 "Le mode CLI n'a pas fonctionné (code $($proc.ExitCode)). Ouverture de l'interface graphique."
        Write-Warn2 "Sélectionnez le disque $DiskNumber, cochez les options souhaitées, puis cliquez sur 'Install'."
        Start-Process -FilePath $ventoyExe -Wait
        Read-Host "Appuyez sur Entrée une fois l'installation Ventoy terminée dans la fenêtre Ventoy2Disk"
    } else {
        Write-Ok "Ventoy installé (mode CLI)."
    }
    Start-Sleep -Seconds 3
} else {
    Write-Info "Installation de Ventoy ignorée (-SkipVentoyInstall)."
}

# --- Étape 2 : identification de la partition de données Ventoy ---
Write-Info "Recherche de la partition de données Ventoy (label 'Ventoy')…"
$volume = $null
for ($i = 0; $i -lt 15 -and -not $volume; $i++) {
    Start-Sleep -Seconds 1
    $volume = Get-Partition -DiskNumber $DiskNumber -ErrorAction SilentlyContinue |
        Get-Volume -ErrorAction SilentlyContinue |
        Where-Object { $_.FileSystemLabel -eq "Ventoy" } |
        Select-Object -First 1
}
if (-not $volume) { Fail "Partition de données Ventoy introuvable après installation." }

$driveLetter = $volume.DriveLetter
if (-not $driveLetter) {
    $part = Get-Partition -DiskNumber $DiskNumber | Where-Object { $_.Size -eq $volume.Size }
    $driveLetter = (Add-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $part.PartitionNumber -AssignDriveLetter -PassThru |
        Get-Partition | Select-Object -ExpandProperty DriveLetter)
}
$root = "$($driveLetter):\"
Write-Ok "Partition Ventoy montée sur $root"

# --- Nettoyage défensif : une ancienne version de ce script a pu écrire
# par erreur nos propres fichiers de config/thème dans le dossier ventoy\
# de la partition VTOYEFI. Ce dossier contient AUSSI les fichiers système
# propres à Ventoy (ventoy.cpio, ventoy.disksig, ventoy_efi.cfg, …) : on
# ne supprime donc JAMAIS le dossier entier, uniquement les fichiers/
# dossiers précis que ce projet a pu y déposer par erreur. ---
$efiVolume = Get-Partition -DiskNumber $DiskNumber -ErrorAction SilentlyContinue |
    Get-Volume -ErrorAction SilentlyContinue |
    Where-Object { $_.FileSystemLabel -eq "VTOYEFI" } |
    Select-Object -First 1
if ($efiVolume) {
    $efiDriveLetter = $efiVolume.DriveLetter
    if (-not $efiDriveLetter) {
        $efiPart = Get-Partition -DiskNumber $DiskNumber | Where-Object { $_.Size -eq $efiVolume.Size }
        $efiDriveLetter = (Add-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $efiPart.PartitionNumber -AssignDriveLetter -PassThru |
            Get-Partition | Select-Object -ExpandProperty DriveLetter)
    }
    if ($efiDriveLetter) {
        $efiResiduePaths = @(
            "$($efiDriveLetter):\ventoy\ventoy.json",
            "$($efiDriveLetter):\ventoy\ventoy_grub.cfg",
            "$($efiDriveLetter):\ventoy\theme"
        )
        foreach ($p in $efiResiduePaths) {
            if (Test-Path $p) {
                Write-Warn2 "Résidu $p trouvé sur la partition VTOYEFI : suppression…"
                Remove-Item -Path $p -Recurse -Force
            }
        }
    }
}

# --- Étape 3 : arborescence des ISO (à remplir vous-même) ---
$paths = @(
    (Join-Path $root "ISOs\Windows"),
    (Join-Path $root "ISOs\Linux\Ubuntu"),
    (Join-Path $root "ISOs\Linux\Kali"),
    (Join-Path $root "ISOs\macOS")
)
foreach ($p in $paths) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
Write-Ok "Dossiers créés sur la clé : ISOs\Windows, ISOs\Linux\Ubuntu, ISOs\Linux\Kali, ISOs\macOS"
Write-Info "Copiez-y vos fichiers .iso (voir docs/LINUX.md, docs/WINDOWS.md, docs/MACOS.md)."

# --- Étape 4 : ISO Windows fourni par l'utilisateur (raccourci optionnel) ---
if ($WindowsIso) {
    if (-not (Test-Path $WindowsIso)) { Fail "Fichier introuvable : $WindowsIso" }
    Write-Info "Copie de l'ISO Windows…"
    Copy-Item -Path $WindowsIso -Destination (Join-Path $root "ISOs\Windows") -Force
}

# --- Étape 5 : image macOS (expérimental, raccourci optionnel) ---
if ($MacosImage) {
    if (-not (Test-Path $MacosImage)) { Fail "Fichier introuvable : $MacosImage" }
    Write-Warn2 "Support macOS expérimental — lisez docs/MACOS.md. Copie en cours…"
    Copy-Item -Path $MacosImage -Destination (Join-Path $root "ISOs\macOS") -Force
}

# --- Étape 6 : personnalisation GRUB2 (config Ventoy) ---
Write-Info "Application de la personnalisation GRUB2/Ventoy…"
$ventoyDest = Join-Path $root "ventoy"
New-Item -ItemType Directory -Path (Join-Path $ventoyDest "theme") -Force | Out-Null
Copy-Item -Path (Join-Path $RepoRoot "ventoy\ventoy.json")     -Destination (Join-Path $ventoyDest "ventoy.json") -Force
Copy-Item -Path (Join-Path $RepoRoot "ventoy\ventoy_grub.cfg") -Destination (Join-Path $ventoyDest "ventoy_grub.cfg") -Force
Copy-Item -Path (Join-Path $RepoRoot "ventoy\theme\*") -Destination (Join-Path $ventoyDest "theme") -Recurse -Force

Cleanup
Write-Ok "Clé USB multiboot prête sur le disque $DiskNumber ($root)."
Write-Info "Prochaines étapes : voir docs/WINDOWS.md et docs/MACOS.md pour compléter Windows/macOS."
