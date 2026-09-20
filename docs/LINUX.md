# Linux — Ubuntu & Kali

Les scripts ne téléchargent rien automatiquement : ils créent les dossiers `ISOs/Linux/Ubuntu/` et `ISOs/Linux/Kali/` sur la clé, et c'est à vous d'y déposer les fichiers `.iso` de votre choix.

## Ubuntu

1. Téléchargez l'ISO **Ubuntu Desktop amd64** de la version souhaitée depuis https://ubuntu.com/download/desktop (ou https://releases.ubuntu.com/ pour les anciennes versions/versions LTS spécifiques).
2. Copiez le fichier `.iso` dans `ISOs/Linux/Ubuntu/` sur la clé.
3. L'ISO Ubuntu Desktop permet à la fois de **l'essayer en direct (live)** et de **l'installer** via l'installateur graphique (Ubiquity/Subiquity selon la version) — ce qui correspond à « faire tourner ou installer ».

## Kali Linux

1. Téléchargez l'ISO **Kali Linux Live amd64** (permet d'essayer sans installer, avec un raccourci « Installer » sur le bureau) ou l'image « installer » complète (offline), depuis https://www.kali.org/get-kali/.
2. Copiez le fichier `.iso` dans `ISOs/Linux/Kali/` sur la clé.

## Vérifier l'intégrité d'une image téléchargée (recommandé)

Avant de copier une ISO sur la clé, vérifiez sa somme de contrôle pour vous assurer qu'elle n'est ni corrompue ni altérée :

```bash
sha256sum ubuntu-24.04.3-desktop-amd64.iso
```

Comparez le résultat avec le fichier `SHA256SUMS` officiel :

- Ubuntu : `https://releases.ubuntu.com/<série>/SHA256SUMS` (ex. `https://releases.ubuntu.com/24.04/SHA256SUMS`)
- Kali : `https://kali.download/base-images/current/SHA256SUMS`

Sous Windows (PowerShell) :

```powershell
Get-FileHash .\ubuntu-24.04.3-desktop-amd64.iso -Algorithm SHA256
```

## Persistance (mode « live » avec sauvegarde des données)

Ventoy supporte les fichiers de persistance pour certaines distributions Linux (ex. `casper-rw` pour les dérivés Ubuntu ; Kali, basé sur Debian, est supporté via son propre mécanisme). Pour l'activer :

1. Créez un fichier de persistance (ex. avec `dd` ou l'outil `CreatePersistentImg.sh`/`.exe` fourni dans l'archive Ventoy).
2. Placez-le à côté de l'ISO concerné, avec le même nom que l'ISO suivi de `.dat` (convention Ventoy), ou configurez l'association précise via `ventoy/ventoy.json` (section `persistence`) — voir la documentation officielle de Ventoy pour la syntaxe exacte selon la version utilisée, car ce projet ne l'active pas par défaut.
