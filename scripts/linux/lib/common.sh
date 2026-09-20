#!/usr/bin/env bash
# Shared helpers for the USB-MultiBoot Linux scripts.
# shellcheck shell=bash

set -euo pipefail

COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_YELLOW=$'\033[0;33m'
COLOR_BLUE=$'\033[0;34m'
COLOR_RESET=$'\033[0m'

log_info()  { printf '%s[*]%s %s\n' "$COLOR_BLUE"  "$COLOR_RESET" "$*"; }
log_ok()    { printf '%s[+]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$*"; }
log_warn()  { printf '%s[!]%s %s\n' "$COLOR_YELLOW" "$COLOR_RESET" "$*" >&2; }
log_error() { printf '%s[x]%s %s\n' "$COLOR_RED"   "$COLOR_RESET" "$*" >&2; }
die()       { log_error "$*"; exit 1; }

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "Ce script doit être exécuté avec sudo/root (accès disque brut requis)."
    fi
}

require_cmd() {
    local cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "Commande requise introuvable : $cmd"
    done
}

# confirm_or_die <message>
# Demande une confirmation stricte ("oui") avant une action destructive.
confirm_or_die() {
    local message="$1"
    local reply
    printf '%s\n' "$message"
    read -r -p "Tapez exactement 'oui' pour continuer : " reply
    [[ "$reply" == "oui" ]] || die "Confirmation refusée, arrêt."
}

# download <url> <destination>
download() {
    local url="$1" dest="$2"
    log_info "Téléchargement : $url"
    curl --fail --location --progress-bar --output "$dest" "$url"
}

# verify_sha256 <file> <expected_sha256>
verify_sha256() {
    local file="$1" expected="$2" actual
    actual="$(sha256sum "$file" | awk '{print $1}')"
    if [[ "${actual,,}" != "${expected,,}" ]]; then
        die "Somme SHA256 invalide pour $file (attendu $expected, obtenu $actual). Fichier potentiellement corrompu ou compromis."
    fi
    log_ok "Somme SHA256 vérifiée : $(basename "$file")"
}

# wait_for_device <path> [timeout_seconds]
wait_for_device() {
    local dev="$1" timeout="${2:-15}" waited=0
    while [[ ! -e "$dev" && "$waited" -lt "$timeout" ]]; do
        sleep 1
        waited=$((waited + 1))
    done
    [[ -e "$dev" ]] || die "Le périphérique $dev n'est pas apparu après ${timeout}s."
}
