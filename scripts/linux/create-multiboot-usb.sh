#!/usr/bin/env bash
#
# create-multiboot-usb.sh — prépare une clé USB multiboot (Windows/Linux/macOS*)
# en s'appuyant sur Ventoy, avec un menu GRUB2 personnalisé.
#
# * macOS : support expérimental non couvert par ce script, voir docs/MACOS.md
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

WORK_DIR="$(mktemp -d /tmp/usb-multiboot.XXXXXX)"
MOUNT_DIR="$WORK_DIR/mnt"
trap 'cleanup' EXIT

cleanup() {
    if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then
        umount "$MOUNT_DIR" 2>/dev/null || true
    fi
    rm -rf "$WORK_DIR"
}

usage() {
    cat <<EOF
Usage: sudo $0 --device /dev/sdX [options]

Options:
  --device DEV            Périphérique de la clé USB, ex: /dev/sdb (requis)
  --gpt                    Utilise le partitionnement GPT (défaut : MBR)
  --secure-boot            Active le support Secure Boot de Ventoy
  --skip-ventoy-install     Ne (ré)installe pas Ventoy, met seulement à jour le contenu
  --windows-iso PATH        Copie un ISO Windows fourni par vous vers ISOs/Windows/
  --macos-image PATH        Copie une image macOS (.img) — voir docs/MACOS.md (expérimental)
  --yes                     Ne pas demander confirmation (dangereux)
  -h, --help                Affiche cette aide

Le script crée les dossiers ISOs/Windows, ISOs/Linux/Ubuntu, ISOs/Linux/Kali
et ISOs/macOS sur la clé : déposez-y vous-même vos ISO (voir docs/LINUX.md,
docs/WINDOWS.md, docs/MACOS.md). --windows-iso et --macos-image ne sont que
des raccourcis optionnels pour copier un fichier déjà présent sur ce PC.

Exemple:
  sudo $0 --device /dev/sdb
EOF
}

DEVICE=""
USE_GPT=0
SECURE_BOOT=0
SKIP_INSTALL=0
WINDOWS_ISO=""
MACOS_IMAGE=""
ASSUME_YES=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --device) DEVICE="$2"; shift 2 ;;
        --gpt) USE_GPT=1; shift ;;
        --secure-boot) SECURE_BOOT=1; shift ;;
        --skip-ventoy-install) SKIP_INSTALL=1; shift ;;
        --windows-iso) WINDOWS_ISO="$2"; shift 2 ;;
        --macos-image) MACOS_IMAGE="$2"; shift 2 ;;
        --yes) ASSUME_YES=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Option inconnue : $1 (voir --help)" ;;
    esac
done

[[ -n "$DEVICE" ]] || { usage; die "--device est requis"; }
[[ -b "$DEVICE" ]] || die "$DEVICE n'est pas un périphérique bloc valide"

require_root
require_cmd curl grep lsblk mount umount mktemp

# --- Sécurité : refuser un disque système ---
ROOT_DISK="$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null || true)"
if [[ -n "$ROOT_DISK" && "$DEVICE" == "/dev/$ROOT_DISK" ]]; then
    die "REFUS : $DEVICE semble être le disque système. Arrêt par sécurité."
fi

log_warn "Le périphérique suivant va être ENTIÈREMENT EFFACÉ :"
lsblk "$DEVICE"
if [[ "$ASSUME_YES" -ne 1 ]]; then
    confirm_or_die "Toutes les données sur $DEVICE seront perdues."
fi

# --- Détermine le suffixe de partition (sdb -> sdb1, nvme0n1 -> nvme0n1p1) ---
part_suffix() {
    local dev="$1" n="$2"
    if [[ "$dev" =~ [0-9]$ ]]; then
        echo "${dev}p${n}"
    else
        echo "${dev}${n}"
    fi
}

# --- Étape 1 : (ré)installation de Ventoy ---
if [[ "$SKIP_INSTALL" -ne 1 ]]; then
    log_info "Récupération de la dernière version de Ventoy…"
    RELEASE_JSON="$WORK_DIR/ventoy-release.json"
    download "https://api.github.com/repos/ventoy/Ventoy/releases/latest" "$RELEASE_JSON"
    VENTOY_URL="$(grep -oE 'https://[^"]+linux\.tar\.gz' "$RELEASE_JSON" | head -n1)"
    [[ -n "$VENTOY_URL" ]] || die "Impossible de trouver l'archive Ventoy Linux dans la release GitHub."
    VENTOY_TAR="$WORK_DIR/ventoy-linux.tar.gz"
    download "$VENTOY_URL" "$VENTOY_TAR"

    log_info "Extraction de Ventoy…"
    tar -xzf "$VENTOY_TAR" -C "$WORK_DIR"
    VENTOY_DIR="$(find "$WORK_DIR" -maxdepth 1 -type d -name 'ventoy-*' | head -n1)"
    [[ -n "$VENTOY_DIR" ]] || die "Extraction de Ventoy échouée."

    VTOY_ARGS=(-i)
    [[ "$USE_GPT" -eq 1 ]] && VTOY_ARGS+=(-g)
    [[ "$SECURE_BOOT" -eq 1 ]] && VTOY_ARGS+=(-s)

    log_info "Installation de Ventoy sur $DEVICE (options: ${VTOY_ARGS[*]})…"
    "$VENTOY_DIR"/Ventoy2Disk.sh "${VTOY_ARGS[@]}" "$DEVICE"
    log_ok "Ventoy installé."
    sleep 2
    partprobe "$DEVICE" 2>/dev/null || true
    sleep 2
else
    log_info "Installation de Ventoy ignorée (--skip-ventoy-install)."
fi

# --- Étape 2 : montage de la partition de données Ventoy (partition 2) ---
DATA_PART="$(part_suffix "$DEVICE" 2)"
wait_for_device "$DATA_PART" 20
mkdir -p "$MOUNT_DIR"
log_info "Montage de $DATA_PART…"
mount "$DATA_PART" "$MOUNT_DIR"

# --- Étape 3 : arborescence des ISO (à remplir vous-même) ---
mkdir -p "$MOUNT_DIR/ISOs/Windows" \
         "$MOUNT_DIR/ISOs/Linux/Ubuntu" \
         "$MOUNT_DIR/ISOs/Linux/Kali" \
         "$MOUNT_DIR/ISOs/macOS"
log_ok "Dossiers créés sur la clé : ISOs/Windows, ISOs/Linux/Ubuntu, ISOs/Linux/Kali, ISOs/macOS"
log_info "Copiez-y vos fichiers .iso (voir docs/LINUX.md, docs/WINDOWS.md, docs/MACOS.md)."

# --- Étape 4 : ISO Windows fourni par l'utilisateur (raccourci optionnel) ---
if [[ -n "$WINDOWS_ISO" ]]; then
    [[ -f "$WINDOWS_ISO" ]] || die "Fichier introuvable : $WINDOWS_ISO"
    log_info "Copie de l'ISO Windows…"
    cp -v "$WINDOWS_ISO" "$MOUNT_DIR/ISOs/Windows/"
fi

# --- Étape 5 : image macOS (expérimental, raccourci optionnel) ---
if [[ -n "$MACOS_IMAGE" ]]; then
    [[ -f "$MACOS_IMAGE" ]] || die "Fichier introuvable : $MACOS_IMAGE"
    log_warn "Support macOS expérimental — lisez docs/MACOS.md. Copie en cours…"
    cp -v "$MACOS_IMAGE" "$MOUNT_DIR/ISOs/macOS/"
fi

# --- Étape 6 : personnalisation GRUB2 (config Ventoy) ---
log_info "Application de la personnalisation GRUB2/Ventoy…"
mkdir -p "$MOUNT_DIR/ventoy/theme"
cp -v "$REPO_ROOT/ventoy/ventoy.json"       "$MOUNT_DIR/ventoy/ventoy.json"
cp -v "$REPO_ROOT/ventoy/ventoy_grub.cfg"   "$MOUNT_DIR/ventoy/ventoy_grub.cfg"
cp -v "$REPO_ROOT/ventoy/theme/theme.txt"   "$MOUNT_DIR/ventoy/theme/theme.txt"

sync
umount "$MOUNT_DIR"
log_ok "Clé USB multiboot prête sur $DEVICE."
log_info "Prochaines étapes : voir docs/WINDOWS.md et docs/MACOS.md pour compléter Windows/macOS."
