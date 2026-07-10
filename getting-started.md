# Pour commencer

**[Español](#es)** · **[English](#en)**

<a id="fr"></a>

## Structure du dépôt

- `mobile/` : application Flutter (Android, iOS, Web, Windows, Linux, macOS)
- `openspec/` : spécifications et artefacts de suivi des changements
- `tools/` : outillage (inclut le SDK Flutter et les outils fournis)

## Démarrage (application Flutter)

Prérequis :

- Un SDK Flutter installé sur votre machine, **ou** l'outillage fourni dans `tools/`

Depuis la racine du dépôt :

```bash
cd mobile
flutter pub get
flutter run --flavor dev
```

Notes :

- Cette application définit des flavors Android (`dev`, `staging`, `prod`). Lancer sans `--flavor` peut amener Gradle à construire `assembleDebug` (sans flavor), ce qui ne produira pas d'APK.
- Préférez les scripts d'aide :
  - `./tool/run_dev.sh`
  - `./tool/run_staging.sh`
  - `./tool/run_prod.sh`

---

**Je sais!** cette page manque d'amour. Sa mise à jour est sur ma liste de tâches à compléter.

---

<a id="es"></a>

**[Français](#fr)** · **[English](#en)**

## Estructura del repositorio

- `mobile/`: aplicación Flutter (Android, iOS, Web, Windows, Linux, macOS)
- `openspec/`: especificaciones y artefactos de seguimiento de cambios
- `tools/`: herramientas (incluye el SDK de Flutter y las herramientas incluidas)

## Arranque (aplicación Flutter)

Requisitos:

- Un SDK de Flutter en su máquina, **o** las herramientas incluidas en `tools/`

Desde la raíz del repositorio:

```bash
cd mobile
flutter pub get
flutter run --flavor dev
```

Notas:

- Esta aplicación define flavors de Android (`dev`, `staging`, `prod`). Ejecutar sin `--flavor` puede hacer que Gradle compile `assembleDebug` (sin flavor), lo que no producirá un APK.
- Prefiera los scripts de ayuda:
  - `./tool/run_dev.sh`
  - `./tool/run_staging.sh`
  - `./tool/run_prod.sh`

---

**¡Lo sé!** a esta página le falta cariño. Actualizarla está en mi lista de tareas pendientes.

<br /><br /><br /><br />

---

<a id="en"></a>

**[Français](#fr)** · **[Español](#es)**

## Repository layout

- `mobile/`: Flutter application (Android, iOS, Web, Windows, Linux, macOS)
- `openspec/`: specifications and change-tracking artifacts
- `tools/`: tooling (includes the Flutter SDK and bundled tools)

## Getting started (Flutter app)

Prerequisites:

- A Flutter SDK on your machine, **or** the tooling under `tools/`

From the repository root:

```bash
cd mobile
flutter pub get
flutter run --flavor dev
```

Notes:

- This app defines Android product flavors (`dev`, `staging`, `prod`). Running without `--flavor` may cause Gradle to build `assembleDebug` (no flavor), which will not produce an APK.
- Prefer the helper scripts:
  - `./tool/run_dev.sh`
  - `./tool/run_staging.sh`
  - `./tool/run_prod.sh`

---

**I know!** this page is lacking love. Updating it is on my to-do list to complete.
