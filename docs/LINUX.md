# Linux — Ubuntu & Kali

## Ubuntu

- Les scripts téléchargent la dernière image **Ubuntu Desktop amd64** de la série indiquée (`--ubuntu-series`, défaut `24.04`, série LTS) depuis `releases.ubuntu.com`, et vérifient son intégrité via le fichier officiel `SHA256SUMS` publié à côté de l'image.
- L'ISO Ubuntu Desktop permet à la fois de **l'essayer en direct (live)** et de **l'installer** via l'installateur graphique (Ubiquity/Subiquity selon la version) — ce qui correspond à « faire tourner ou installer ».
- Pour changer de série (ex. la dernière version non-LTS) : `--ubuntu-series 24.10`.

## Kali Linux

- Les scripts téléchargent la dernière image **Kali Linux Live amd64** depuis `kali.download/base-images/current/`, vérifiée via le `SHA256SUMS` officiel du même dossier.
- L'image live permet également d'essayer Kali sans rien installer, avec un raccourci « Installer » sur le bureau pour une installation complète si souhaité.
- Pour une image « installer » complète (offline, tous les paquets inclus) plutôt que « live », téléchargez-la manuellement depuis https://www.kali.org/get-kali/ et placez-la dans `ISOs/Linux/Kali/` sur la clé.

## Persistance (mode « live » avec sauvegarde des données)

Ventoy supporte les fichiers de persistance pour certaines distributions Linux (ex. `casper-rw` pour les dérivés Ubuntu, y compris Kali qui est basé sur Debian et supporté via son propre mécanisme). Pour l'activer :

1. Créez un fichier de persistance (ex. avec `dd` ou l'outil `CreatePersistentImg.sh`/`.exe` fourni dans l'archive Ventoy).
2. Placez-le à côté de l'ISO concerné, avec le même nom que l'ISO suivi de `.dat` (convention Ventoy), ou configurez l'association précise via `ventoy/ventoy.json` (section `persistence`) — voir la documentation officielle de Ventoy pour la syntaxe exacte selon la version utilisée, car ce projet ne l'active pas par défaut.

## Vérification manuelle (optionnelle)

Vous pouvez toujours vérifier vous-même une image après téléchargement :

```bash
sha256sum ISOs/Linux/Ubuntu/ubuntu-*.iso
sha256sum ISOs/Linux/Kali/kali-linux-*.iso
```

Comparez avec les fichiers `SHA256SUMS` publiés respectivement sur `releases.ubuntu.com` et `kali.download`.
