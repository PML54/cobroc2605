# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on a connected device or emulator
flutter run

# Build
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web

# Analyze (lint)
flutter analyze

# Run tests
flutter test
flutter test test/widget_test.dart   # single test file

# Get/update dependencies
flutter pub get
flutter pub upgrade
```

## Architecture Overview

**cobroc** is a Flutter app for discovering and ranking French *brocantes* (flea markets). It scrapes [brocabrac.fr](https://brocabrac.fr) and presents events ranked by a configurable scoring algorithm.

### Data flow

1. `ManagerPML` (main screen) builds URLs like `https://brocabrac.fr/recherche?ou=<deptCode>&c=bro,vgr,bra&d=<date>` for each department in the active region.
2. `NetworkHelper` (`networking.dart`) fetches each URL, parses HTML with the `html` package, and extracts `application/ld+json` Event schema blocks to build `Brocabrac` objects.
3. `ManagerPML` computes distances, density, and scoring, then sorts and displays events.

### Key classes

- **`Brocabrac`** (`pmltools.dart`) — the core data model for a single brocante event. Fields include location, status (`OK`/`KO`), exposant count, revenue rating, distance from reference point, and density score.
- **`ManageCobrac`** (`pmltools.dart`) — argument wrapper for navigating to detail screens (passes the full list + selected item).
- **`GoToMarket`** (`pmltools.dart`) — holds map trip data (markers, center coords).
- **`Historic`** (`historibroc.dart`) — a hardcoded list of previously-visited brocantes. Used to mark events as "already seen" (`brocDejaVu`). The list (`listHistoric`) is compiled into the binary — no external DB.

### Services (`lib/services/`)

| Service | Responsibility |
|---|---|
| `GeoService` | Haversine distance calculation |
| `ScoringService` | Weighted scoring (exposants, density, revenue, historic, distance) → ranking |
| `FilterService` | Filter brocante list by exposant count category or historic-only |
| `DateService` | Compute next Saturday/Sunday date strings for the date picker |
| `HolidayService` | French public holiday calendar (Pâques, Ascension, etc.) + brocante-day logic (Sam/Dim/Férié); week-level and inter-week navigation |
| `LocationService` | GPS acquisition + reverse geocode to French département |
| `StorageService` | `SharedPreferences` persistence (rayon, scoring weights, active location) |

### Screens

| File | Screen |
|---|---|
| `managerpml.dart` | Main list screen — entry point, orchestrates everything |
| `detailedBrocante.dart` | Detail view for a single brocante (long-press from list) |
| `zee.dart` | Alternative detail view (`DetailBroc`) with historic-analysis panel (`analyzeBrocante`) |
| `monplan.dart` | Interactive map using `flutter_map` + OpenStreetMap tiles |
| `mapcobrac.dart` | Département-grid map view for selecting a custom trip |
| `departements.dart` | France département selector using `interactive_country_map` |
| `datate.dart` | Date picker screen (`ConfigBrocante`) |
| `histeric.dart` | Browse/search the hardcoded historic visits |

### Widgets (`lib/widgets/brocante/`)

- `BrocanteListView` — left panel, full list sorted by distance from reference point
- `BrocanteListReduce` — right panel, filtered list sorted by distance from selected point
- `RayonDialog` — settings dialog for density radius and scoring weights
- `FiltreExposantsDialog` — filter picker by exposant count category

### Models (`lib/models/`)

- `FiltreCategorieExposants` — enum for exposant count filter
- `ConfigLieu` — location preset model

### Static data

- `communestchinos.dart` — `listCommunes`: a large list of French communes with revenue/population data. Used to enrich brocantes with income data for scoring.
- `historibroc.dart` — `listHistoric`: hardcoded visit history.
- `diverspml.dart` — French day/month name arrays and `BreakDate` utility.

### Location presets

`ManagerPML` has three hardcoded base locations (Larris, Portbail, Loon-Plage) plus a GPS mode. The active location determines which département codes are fetched and which coordinates are used as the distance reference.

### Scoring

`ScoringService.calculerScoreOptimal()` combines four weighted criteria (exposants, local density, commune revenue, historic visits) with an optional distance factor. Weights are persisted via `SharedPreferences` and configurable from the settings dialog. The top 3 ranked events are highlighted with gold/silver/bronze colors in the list.

### Historic analysis (`zee.dart`)

`analyzeBrocante(ville)` queries `listHistoric` for all past visits to a city and returns a composite score (qualité, taille, potentiel achat, commentaires, note globale). Displayed in the `DetailBroc` detail screen as an analysis panel. Simple keyword-based sentiment from `histAvis`/`histDetail` fields.

### Key dependencies

| Package | Use |
|---|---|
| `http` | HTTP requests to brocabrac.fr |
| `html` | HTML parsing, ld+json extraction |
| `google_maps_flutter` | Native Google Maps (used in `zee.dart` single-marker view) |
| `flutter_map` + `latlong2` | OSM tile maps (`monplan.dart`) |
| `interactive_country_map` | Département selector (`departements.dart`) |
| `geolocator` + `geocoding` | GPS + reverse geocode |
| `shared_preferences` | Settings persistence |
| `diacritic` | Accent-insensitive string comparison |
| `intl` | Date formatting |
| `sqlite3` | Declared dependency (not actively used in current screens) |
