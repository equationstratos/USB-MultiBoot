# macOS — lisez avant toute tentative

**macOS est le cas le plus délicat de ce projet, légalement et techniquement. Ce dépôt fournit un dossier `ISOs/macOS/` et un paramètre `--macos-image` / `-MacosImage` par cohérence avec les autres OS, mais ce chemin est expérimental, non testé de façon exhaustive, et non garanti.**

## Contraintes légales

Le CLUF (EULA) de macOS restreint son installation et son exécution aux ordinateurs de marque Apple. Installer macOS sur du matériel non-Apple (« Hackintosh ») est une violation des conditions d'utilisation d'Apple. Ce projet :

- ne fournit, ne télécharge, ni ne distribue d'image ou d'installateur macOS ;
- ne doit être utilisé pour macOS que sur du matériel Apple réel, ou dans un cadre où vous avez vérifié que cela respecte les conditions applicables (ex. machine virtuelle sur matériel Apple).

## Contraintes techniques

Contrairement à Windows et Linux, **Ventoy ne supporte pas nativement le boot d'un ISO ou DMG macOS** — le format et le processus de démarrage d'un installateur macOS (créé via `createinstallmedia`) sont spécifiques à Apple et ne sont pas des ISO ISO9660 classiques.

Sur un vrai Mac, il n'y a d'ailleurs pas besoin de GRUB/Ventoy : la sélection d'un disque de démarrage se fait via le gestionnaire de démarrage interne d'Apple (touche **Option/⌥** au démarrage), pas via un menu GRUB.

### Ce qui est réellement possible

1. **Clé USB macOS dédiée et séparée** (recommandé) : sur un Mac, utilisez `createinstallmedia` (fourni par l'application d'installation téléchargée depuis l'App Store) pour créer une clé USB d'installation macOS classique. Cette clé ne passe pas par Ventoy ; elle démarre directement via le gestionnaire de boot Apple.

2. **Image disque brute (« whole-disk ») en boot chaîné — expérimental** : Ventoy propose un mode de démarrage d'images disque complètes (`.img`, format « raw »), pensé pour d'autres cas d'usage (ex. images de test). En théorie, une image brute (`dd`) d'une clé USB d'installation macOS déjà fonctionnelle pourrait être placée dans `ISOs/macOS/` et proposée par Ventoy comme un disque virtuel complet. **Ce chemin n'est ni documenté ni garanti par Ventoy pour macOS, n'a pas été validé dans ce projet, et peut ne pas fonctionner selon le matériel, la puce (Intel vs Apple Silicon — Apple Silicon n'a de toute façon aucun support Hackintosh) et la version de Ventoy.** Si vous l'essayez :
   - créez d'abord une clé USB d'installation macOS valide et fonctionnelle (via `createinstallmedia`, sur du matériel où l'usage est légitime) ;
   - clonez-la en image brute : `sudo dd if=/dev/diskN of=macos-install.img bs=4M status=progress` ;
   - copiez `macos-install.img` dans `ISOs/macOS/` (ou via `--macos-image`) ;
   - testez sur du matériel où le résultat, s'il ne fonctionne pas, n'a aucune conséquence critique.

3. **Machine virtuelle** : pour un usage de test/développement, une VM macOS (avec les outils et licences appropriés, sur matériel Apple) est une alternative plus simple et plus fiable qu'un boot direct depuis une clé multiboot.

## En résumé

- Windows et Linux (Ubuntu/Kali) : entièrement supportés et automatisés par ce projet via Ventoy.
- macOS : **hors du périmètre garanti** de ce projet. Préférez une clé USB macOS dédiée créée avec les outils Apple officiels ; le dossier `ISOs/macOS/` de cette clé multiboot n'est là que pour les utilisateurs avertis qui veulent expérimenter, à leurs risques, avec la portée légale et technique décrite ci-dessus.
