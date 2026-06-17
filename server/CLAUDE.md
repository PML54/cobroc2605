# cobroc-server

Serveur REST local pour la base **historibroc** — historique des visites de brocantes de PML et FRA.  
Objectif principal : partager et modifier la base depuis n'importe quelle machine du réseau local.

## Stack

| Composant | Détail |
|-----------|--------|
| Runtime | Python 3.11, venv `.venv/` |
| Framework | FastAPI + Uvicorn |
| Base de données | SQLite `db/historibroc.db` |
| Validation IA | Claude Haiku via `agent/validator.py` |
| Config | `.env` (copie de `.env.example`) |

## Démarrage

```bash
source .venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8765 --reload
```

Accès réseau local : `http://<IP_DU_MAC>:8765`  
Swagger UI : `http://<IP_DU_MAC>:8765/docs`

## Structure des fichiers

```
server.py                           # Application FastAPI — toutes les routes
static/index.html                   # Appli web de saisie d'une visite (servie sur / et /static)
agent/validator.py                  # Agent Claude Haiku : valide chaque entrée avant insertion
db/schema.sql                       # DDL SQLite (tables lieux + historic + index)
db/historibroc.db                   # Base SQLite (~2237 entrées + 672 lieux)
scripts/import_dart.py              # Migration initiale depuis historibroc.dart
scripts/export_dart.py              # Export base → lib/historibroc.dart (projet Flutter cobroc)
scripts/migrate_lieux.py            # Migration 1 : remplace la VIEW lieux par une TABLE, ajoute lieu_id à historic
scripts/migrate_historic_lieux.py   # Migration 2 : peuple lieux depuis historic et relie lieu_id
scripts/migrate_lieu_endroit.py     # Migration 3 : ajoute parking/rues/stade/espace à lieux
requirements.txt                    # fastapi, uvicorn, anthropic, python-dotenv
.env                                # ANTHROPIC_API_KEY + DB_PATH (ne pas commiter)
```

## Table `lieux` — champs

| Champ | Type | Description |
|-------|------|-------------|
| `id` | INTEGER PK | Auto-increment |
| `nom` | TEXT | Nom du marché/événement (ex : "Brocante d'ABLEIGES") |
| `ville` | TEXT | Commune (forme canonique) |
| `ville_normalized` | TEXT | Commune sans accents en majuscules (recherche) |
| `code_postal` | INTEGER | Code postal français |
| `adresse` | TEXT | Lieu précis |
| `recurrence` | TEXT | `"mensuel"`, `"annuel"`, `"ponctuel"`, etc. |
| `parking` | INTEGER 0/1 | Endroit : parking |
| `rues` | INTEGER 0/1 | Endroit : rues |
| `stade` | INTEGER 0/1 | Endroit : stade |
| `espace` | INTEGER 0/1 | Endroit : espace |
| `created_at` | TEXT | `datetime('now')` à l'insertion |

## Table `historic` — champs

| Champ | Type | Description |
|-------|------|-------------|
| `id` | INTEGER PK | Auto-increment |
| `hist_name` | TEXT | `"PML"` ou `"FRA"` |
| `hist_date` | TEXT | Format `AAAA-MM-JJ` |
| `hist_good` | INTEGER 0–5 | Note de la brocante |
| `hist_ville` | TEXT | Commune (MAJUSCULES conseillé) |
| `hist_code_postal` | INTEGER | Code postal français |
| `hist_adresse` | TEXT | Lieu précis |
| `hist_nb_expo` | INTEGER | Nombre d'exposants estimé |
| `hist_pml_dep` | INTEGER | Dépenses PML (€) |
| `hist_fra_dep` | INTEGER | Dépenses FRA (€) |
| `hist_maison_dep` | INTEGER | Dépenses maison (€) |
| `hist_avis` | TEXT | Commentaire libre |
| `hist_detail` | TEXT | Achats détaillés |
| `validated` | INTEGER 0/1 | Approuvé par l'agent Claude |
| `agent_notes` | TEXT | Notes de l'agent après validation |
| `created_at` | TEXT | `datetime('now')` à l'insertion |
| `ville_normalized` | TEXT | Commune sans accents en majuscules (recherche) |
| `lieu_id` | INTEGER FK | Référence vers `lieux.id` (nullable pour anciennes entrées) |

## Routes API

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/lieux` | Liste (filtres : `ville` = **début de ville**, `cp`, `sort`) |
| GET | `/lieux/{id}` | Lieu par ID |
| POST | `/lieux` | Créer un lieu |
| PUT | `/lieux/{id}` | Modifier un lieu |
| DELETE | `/lieux/{id}` | Supprimer (refusé si utilisé dans historic) |
| GET | `/historic` | Liste (filtres : `ville` = **début de ville**, `name`, `validated`, `sort`, `limit`, `offset`) |
| GET | `/historic/{id}` | Entrée par ID |
| POST | `/historic` | Créer (déclenche validation agent) |
| PUT | `/historic/{id}` | Modifier (re-valide via agent) |
| DELETE | `/historic/{id}` | Supprimer |
| GET | `/export/dart` | Génère `historibroc.dart` en texte brut |
| GET | `/stats` | Total, validés, en attente, répartition PML/FRA |

Le filtre `ville` (sur `/lieux` et `/historic`) matche **en début de nom uniquement** (`{ville}%`), sans accents et insensible à la casse (fonction `NOACCENT`).

## Appli web de saisie (`static/index.html`)

Formulaire « Nouvelle visite » servi sur `/` (redirige vers `/static/index.html`). Page HTML/CSS/JS autonome, sans build.

- **Visiteur** : bascule PML / FRA. **Date** : pré-remplie sur le **jour courant** (modifiable par le user), **obligatoire**. **Note** : étoiles 0–5.
- **Lieu** : recherche par **début de ville, dès la 1re lettre, forcée en MAJUSCULES** ; la liste affiche le couple **ville + adresse** (+ nb de visites) pour distinguer les lieux d'une même ville. La sélection remplit CP/adresse en **lecture seule** et fixe `lieu_id` (obligatoire pour enregistrer).
- **Nouveau lieu** : créé dans une **modale dédiée** (Ville, CP, Adresse, Nom/Récurrence optionnels, cases **Endroit** parking/rues/stade/espace) → `POST /lieux` puis auto-sélection dans le CR.
- **Détail des achats** : lignes **description + prix entier** distinctes, recomposées dans `hist_detail` au format `desc=prix€+…` (compatible historique).
- Les champs ville/CP/adresse neutralisent l'autofill navigateur (ids neutres + `readonly` levé au focus).

## Variables d'environnement (`.env`)

```
ANTHROPIC_API_KEY=sk-ant-...   # Obligatoire pour la validation agent
DB_PATH=./db/historibroc.db    # Chemin vers la base SQLite
SERVER_HOST=0.0.0.0            # Écoute sur tout le réseau
SERVER_PORT=8765
```

## Agent de validation (Claude Haiku)

Chaque `POST /historic` et `PUT /historic/{id}` appelle `agent/validator.py` qui :
1. Vérifie le format de la date et la cohérence ville/code postal
2. Détecte les doublons potentiels (même ville + date + name)
3. Suggère des corrections (`hist_ville`, `hist_avis`)
4. Retourne `{"approved": bool, "notes": str, "suggestions": {...}}`

Les suggestions approuvées sont appliquées avant insertion.

## Export vers l'appli Flutter `cobroc`

L'appli `cobroc` (iPhone surtout, web parfois) **ne lit PAS la base SQLite au runtime**.
Elle consomme un fichier Dart généré, **`lib/historibroc.dart`** (racine du monorepo),
qui contient la classe `Historic` et une liste `listHistoric` en dur (données embarquées
au build → offline). Modifier la `.db` seule ne met donc **rien** à jour.

> Monorepo : ce dossier est `server/` sous la racine `cobroc`. Les commandes
> ci-dessous se lancent depuis `server/` ; l'export écrit dans `../lib/historibroc.dart`.

**Workflow de mise à jour des données de l'appli :**

```bash
# 1. Régénérer le fichier Dart depuis la base (depuis server/)
python scripts/export_dart.py            # écrit ../lib/historibroc.dart
# (ou : curl http://localhost:8765/export/dart > ../lib/historibroc.dart)

# 2. Rebuilder/redéployer l'appli Flutter (étape indispensable, données bundlées)
```

Points clés de `scripts/export_dart.py` :
- N'exporte que les entrées **`validated = 1`**. Les saisies du formulaire web sont
  `validated = 0` tant que l'agent ne les a pas approuvées → **elles ne s'exportent pas**.
- Le template de la classe `Historic` (dans le script) doit rester **synchronisé** avec
  ce qu'attend le code Dart de `cobroc` (ex. la méthode statique `matchesVille`, utilisée
  par `detailedBrocante.dart`). Toute régénération **écrase** `historibroc.dart`.
- Les champs enrichis (`heureArrivee`, `pluie`, `arriveeTard`, et l'endroit du lieu
  `parking`/`rues`/`stade`/`espace` via LEFT JOIN `lieux`) sont émis en **paramètres
  nommés optionnels**, et **seulement s'ils sont non-défaut** → les anciennes lignes
  restent inchangées, rétro-compatibles.
- Ces champs sont **transportés** dans les objets `Historic` et **affichés** dans la
  vue d'une visite (`lib/histeric.dart`, badges conditionnels heure/pluie/endroit).
- Valider le fichier généré : `cd .. && dart analyze lib/historibroc.dart`.

## Commandes utiles

```bash
# Stats rapides
curl http://localhost:8765/stats

# Recherche par ville
curl "http://localhost:8765/historic?ville=PONTOISE&limit=10"

# Export Dart (après ajouts validés)
curl http://localhost:8765/export/dart > ../lib/historibroc.dart

# Réimporter depuis Dart (reset complet)
python scripts/import_dart.py
```

## Accès depuis le réseau local

Le serveur démarre avec `--host 0.0.0.0`, ce qui l'expose sur toutes les interfaces réseau.  
Depuis un autre appareil sur le même Wi-Fi/LAN, utiliser l'IP locale du Mac serveur :

```bash
# Trouver l'IP locale
ipconfig getifaddr en0   # Wi-Fi
ipconfig getifaddr en1   # Ethernet
```

Exemple d'accès depuis un autre Mac : `http://192.168.1.X:8765/docs`
