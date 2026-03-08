# mc_multicharacter

Script **multicharacter complet** pour FiveM (ESX / QB / standalone), avec:

- Interface NUI moderne (création, suppression, sélection)
- Gestion des slots par licence
- Isolation du joueur en routing bucket pendant la sélection
- Sauvegarde périodique de la dernière position
- Validation serveur des données (anti-injection basique)
- Base SQL dédiée simple et performante

---

## Dépendances

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)

Compatibilité framework:

- ESX (détection auto)
- QBCore (détection auto)
- Standalone (fallback)

---

## Installation

1. Place le dossier `mc_multicharacter` dans tes `resources`.
2. Exécute `sql/mc_multicharacter.sql` dans ta base de données.
3. Ajoute à ton `server.cfg` (ordre recommandé):

```cfg
ensure oxmysql
ensure ox_lib
ensure mc_multicharacter
```

4. Configure `config.lua` selon ton serveur (slots, spawn, règles de nom, etc.).

---

## Configuration importante

Dans `config.lua`:

- `Config.Framework = 'auto'` (ou `esx` / `qb`)
- `Config.MaxSlotsPerLicense = 6`
- `Config.Selection.SpawnHidden` et `Config.Selection.Camera`
- `Config.DefaultSpawn`

---

## Événements / callbacks NUI

Callbacks serveur:

- `mc_multicharacter:getCharacters`
- `mc_multicharacter:createCharacter`
- `mc_multicharacter:deleteCharacter`
- `mc_multicharacter:selectCharacter`

Événements serveur:

- `mc_multicharacter:enterSelection`
- `mc_multicharacter:saveLastPosition`

Commande client:

- `/multicharacter` (ouvre l’interface)

---

## Notes intégration framework

Le script fournit une base propre, mais la phase “chargement complet joueur” dépend de ton écosystème (inventaire, skin, housing, jobs custom).

Tu peux brancher tes scripts ici:

- `server/framework.lua` → `MC.Framework.ApplyCharacter`
- `client/main.lua` → `spawnSelectedCharacter`

---

## Bonnes pratiques production

- Active un anti-cheat côté serveur.
- Loggue les créations/suppressions de personnages.
- Ajoute une whitelist ou un ACL admin pour les opérations sensibles.
- Sauvegarde la DB régulièrement.

