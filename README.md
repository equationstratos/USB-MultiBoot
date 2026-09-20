# USB-MultiBoot

Créez une clé USB multiboot permettant de **tester (live) ou d'installer** :

- 🪟 **Windows** (10/11 — ISO fourni par vous, via Microsoft)
- 🐧 **Linux** — Ubuntu et Kali Linux (téléchargement + vérification automatique)
- 🍎 **macOS** — support expérimental, voir [docs/MACOS.md](docs/MACOS.md) (contraintes légales et techniques importantes)

Le projet s'appuie sur [Ventoy](https://www.ventoy.net/) (GPL-3.0, non inclus dans ce dépôt — téléchargé à l'exécution) : vous copiez simplement des fichiers `.iso` sur la clé, Ventoy génère un menu de boot GRUB2 qui les détecte automatiquement. Ce dépôt ajoute :

- des scripts d'automatisation (déploiement de Ventoy, téléchargement/vérification des ISO, organisation des dossiers) ;
- une **personnalisation GRUB2** (menu en vue arborescente par OS, couleurs par catégorie, thème) via les points d'extension officiels de Ventoy — sans toucher au moteur interne de Ventoy, qui reste à jour via ses propres mises à jour.

## ⚠️ Avertissements

- **Toutes les données de la clé USB seront effacées.** Les scripts demandent une confirmation explicite avant d'écrire sur un disque.
- **Windows** : vous devez fournir votre propre ISO, obtenu légalement via l'outil de création de média Microsoft. Ce dépôt ne télécharge ni ne distribue d'ISO Windows.
- **macOS** : l'EULA d'Apple restreint macOS aux machines de marque Apple. Ce projet ne fournit ni ne distribue d'image macOS ; voir [docs/MACOS.md](docs/MACOS.md) pour les options légales et les limites techniques réelles (Ventoy ne boote pas nativement macOS).

## Structure du dépôt

```
scripts/linux/create-multiboot-usb.sh   # Script principal (Linux/bash)
scripts/windows/Create-MultibootUSB.ps1 # Script principal (Windows/PowerShell)
ventoy/ventoy.json                      # Config Ventoy : vue arborescente, couleurs par OS
ventoy/ventoy_grub.cfg                  # Personnalisation GRUB2 (couleurs, timeout, thème)
ventoy/theme/theme.txt                  # Thème GRUB2 personnalisé (texte, pas d'image requise)
docs/WINDOWS.md                         # Comment ajouter Windows
docs/MACOS.md                           # Options et limites pour macOS
docs/LINUX.md                           # Détails Ubuntu / Kali, persistance
docs/CUSTOMIZATION.md                   # Comment personnaliser davantage le menu GRUB2
```

## Démarrage rapide

### Linux

```bash
sudo ./scripts/linux/create-multiboot-usb.sh --device /dev/sdX --download-ubuntu --download-kali
```

### Windows (PowerShell en administrateur)

```powershell
.\scripts\windows\Create-MultibootUSB.ps1 -DiskNumber 1 -DownloadUbuntu -DownloadKali
```

Remplacez `/dev/sdX` / `-DiskNumber` par l'identifiant réel de votre clé USB (les scripts listent les disques disponibles et demandent confirmation avant toute écriture).

Ensuite :

1. Ajoutez votre ISO Windows dans `ISOs/Windows/` sur la clé (voir [docs/WINDOWS.md](docs/WINDOWS.md)).
2. Pour macOS, lisez impérativement [docs/MACOS.md](docs/MACOS.md) avant toute tentative.
3. Démarrez sur la clé USB (F12/F10/Échap selon le PC), sélectionnez le mode UEFI, et choisissez l'ISO dans le menu Ventoy.

## Pourquoi Ventoy plutôt qu'un GRUB2 « from scratch » ?

Booter Windows et Linux directement en loopback depuis un GRUB2 écrit à la main nécessite de réimplémenter des mécanismes complexes et fragiles (wimboot, gestion NTFS, exFAT, Secure Boot, détection UEFI/BIOS). Ventoy le fait déjà de façon robuste et activement maintenue. Ce dépôt personnalise son GRUB2 via ses points d'extension officiels plutôt que de dupliquer ce travail — voir [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) pour le détail de ce qui est personnalisé et comment aller plus loin.

## Licence

Le code de ce dépôt est sous licence MIT (voir [LICENSE](LICENSE)). Ventoy est un logiciel tiers sous licence GPL-3.0, téléchargé séparément par les scripts.
