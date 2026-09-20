# Windows

Ce projet ne télécharge ni ne redistribue d'ISO Windows : vous devez l'obtenir vous-même, légalement, auprès de Microsoft.

## 1. Obtenir l'ISO

- **Windows 11** : https://www.microsoft.com/software-download/windows11 (outil de création de média, ou téléchargement direct de l'ISO).
- **Windows 10** : https://www.microsoft.com/software-download/windows10

Choisissez l'édition et la langue souhaitées, puis téléchargez le fichier `.iso`.

## 2. Ajouter l'ISO à la clé

Deux options :

- Au moment de la création de la clé :
  ```bash
  sudo ./scripts/linux/create-multiboot-usb.sh --device /dev/sdX --windows-iso /chemin/vers/Win11.iso
  ```
  ```powershell
  .\scripts\windows\Create-MultibootUSB.ps1 -DiskNumber 1 -WindowsIso "C:\chemin\vers\Win11.iso"
  ```
- Ou simplement en copiant le fichier à la main dans `ISOs/Windows/` sur la clé une fois celle-ci préparée. Ventoy détecte les nouveaux ISO sans avoir besoin d'être réinstallé.

## 3. Points d'attention

- **exFAT et gros fichiers** : la partition de données Ventoy est en exFAT, qui n'a pas la limite de 4 Go de FAT32 — un ISO Windows (souvent > 5 Go) est donc supporté nativement, sans découpage.
- **Secure Boot** : pour démarrer l'installateur Windows avec Secure Boot activé, installez Ventoy avec `--secure-boot` (Linux) / `-SecureBoot` (Windows). Sinon, désactivez temporairement Secure Boot dans le firmware UEFI de la machine cible.
- **Mode d'installation** : dans le menu Ventoy, un sous-menu apparaît pour les ISO Windows proposant notamment le mode « Normal » (recommandé pour la plupart des versions récentes de Windows 10/11).
- **Bypass des prérequis Windows 11** (TPM 2.0 / Secure Boot / RAM) : si nécessaire, activez `VTOY_WIN11_BYPASS_CHECK` dans `ventoy/ventoy.json` (voir [docs/CUSTOMIZATION.md](CUSTOMIZATION.md)) — à utiliser en connaissance de cause, hors garantie Microsoft sur du matériel non certifié.

## 4. Démarrage / installation

Depuis le menu de boot Ventoy, sélectionnez l'ISO Windows en mode **UEFI**, laissez l'installateur Windows classique se lancer, puis suivez l'assistant (« Réparer l'ordinateur » pour une réparation, ou « Installer maintenant » pour une nouvelle installation).
