# Personnaliser le menu GRUB2

Ce projet ne réécrit pas le moteur interne de Ventoy (qui détecte les ISO, gère le loopback, etc.) — il le personnalise via les points d'extension **officiels et stables** de Ventoy, situés dans le dossier `ventoy/` à la racine de la partition de données :

| Fichier                      | Rôle                                                                 |
|-------------------------------|-----------------------------------------------------------------------|
| `ventoy/ventoy.json`          | Configuration de Ventoy : options globales, classes de menu, alias   |
| `ventoy/ventoy_grub.cfg`      | Snippet GRUB2 additionnel, inclus en fin de `grub.cfg` généré         |
| `ventoy/theme/theme.txt`      | Thème graphique GRUB2 (couleurs, police, disposition du menu)         |

Ces trois fichiers sont fournis dans ce dépôt sous `ventoy/` et copiés sur la clé par les scripts (étape finale). Vous pouvez les modifier avant exécution, ou directement sur la clé déjà préparée (relancez ensuite le script avec `--skip-ventoy-install` / `-SkipVentoyInstall` pour ré-appliquer votre config sans toucher à l'installation de Ventoy elle-même).

## Ce qui est déjà personnalisé dans ce dépôt

- **Vue arborescente** (`VTOY_TREE_VIEW_MENU_STYLE`) : le menu regroupe automatiquement les ISO par dossier (`ISOs/Windows`, `ISOs/Linux/Ubuntu`, `ISOs/Linux/Kali`, `ISOs/macOS`) plutôt que d'afficher une liste plate.
- **Alias de menu** (`menu_alias`) : des libellés lisibles (« Ubuntu - Essayer ou installer », etc.) plutôt que le nom brut du fichier ISO.
- **Classes de menu** (`menu_class`) : chaque OS reçoit une classe CSS-like (`cls_windows`, `cls_ubuntu`, `cls_kali`, `cls_macos`) exploitable pour du style avancé.
- **Thème** (`theme.txt` + `theme/select_*.png`) : polices, couleurs, disposition du cadre de menu, et une barre de surbrillance cyan derrière l'entrée sélectionnée (mécanisme `selected_item_pixmap_style`, le même que celui du thème par défaut de Ventoy). Les images sont de simples PNG unis générés par script, sans dépendance externe.
- **Timeouts et couleurs de secours** (`ventoy_grub.cfg`) : délai du menu, couleurs en mode texte si le thème graphique ne charge pas.

## Aller plus loin

- **Fond d'écran** : ajoutez une image (`background-image: "background.png"` en tête de `theme.txt`) et placez le fichier dans `ventoy/theme/`. Résolution conseillée : celle définie par `gfxmode` dans `ventoy.json` (1024x768 par défaut, modifiable).
- **Icônes par OS** : Ventoy peut associer une icône par ISO via un fichier `.png` de même nom que l'ISO placé dans `ventoy/theme/icons/` (voir la documentation officielle Ventoy pour la convention exacte de nommage, qui a évolué selon les versions).
- **Timeout et mode par défaut** : ajustez `VTOY_MENU_TIMEOUT` / `VTOY_DEFAULT_MENU_MODE` dans `ventoy.json`.
- **Entrées manuelles supplémentaires** : vous pouvez ajouter des blocs `menuentry { ... }` GRUB2 classiques directement dans `ventoy_grub.cfg` (ex. pour un outil de diagnostic memtest86, un accès au firmware UEFI, etc.), en plus des entrées générées automatiquement par Ventoy pour vos ISO.
- **Référence complète** : la documentation officielle de Ventoy (https://www.ventoy.net/en/plugin_theme.html et pages associées) détaille l'ensemble des clés disponibles dans `ventoy.json` et la syntaxe de thème, qui évolue avec les versions — vérifiez-la si un réglage avancé ne produit pas l'effet attendu.

## Ne pas faire

- Ne modifiez pas le `grub.cfg` généré par Ventoy directement sur la clé : il est régénéré à chaque boot et vos changements seraient perdus. Passez toujours par `ventoy_grub.cfg` (inclus automatiquement) ou par `ventoy.json`.
- Ne renommez pas le dossier `ventoy/` ni les fichiers `ventoy.json` / `ventoy_grub.cfg` : ce sont des noms fixes attendus par Ventoy.
