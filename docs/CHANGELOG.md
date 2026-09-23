# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/it/1.1.0/). Ogni voce va aggiunta sotto "Unreleased" al momento della modifica, non a posteriori.

## [Unreleased]

### Added
- M0 skeleton tecnico: arena 1600x1000 con muri e camera, player twin-stick (movimento 8 dir, mira mouse/stick destro), arma con fire-rate da `WeaponData`, proiettili con object pool, nemico base che insegue e rinasce, danno da contatto con i-frames, hit-flash, HUD HP/EXP.
- Componenti riusabili `Health`, `Hitbox`, `Hurtbox`, `HitFlash`, `Weapon`, `ProjectilePool`.
- Dati come Resource: `WeaponData`, `EnemyData`, `PlayerStats` (+ `.tres` iniziali).
- Autoload `RunManager` (exp di run), input map, collision layers nominati.
- BEST_PRACTICES: API poolable, componenti combat, composition root, tabella collision layers.
- Documento di design iniziale (`docs/GDD.md`): scope MVP, core loop hub/run/estrazione, doppia progressione, extraction shooter layer.
- Setup repo git locale, changelog, best practice di sviluppo.

### Changed
- `CHANGELOG.md` spostato in `docs/` (coerente con i riferimenti in GDD e BEST_PRACTICES).

