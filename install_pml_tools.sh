#!/bin/bash

# Configuration des couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour les messages de log
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifie les paramètres
if [ "$#" -ne 2 ]; then
    error "Usage: $0 <source_project_dir> <destination_dir>"
    echo "Example: $0 /path/to/your/flutter/project /path/to/new/pml_tools"
    exit 1
fi

SOURCE_DIR="$1"
DEST_DIR="$2"

# Vérifie les répertoires source
if [ ! -d "$SOURCE_DIR" ]; then
    error "Répertoire source non trouvé: $SOURCE_DIR"
    exit 1
fi

if [ ! -f "$SOURCE_DIR/pml.yaml" ]; then
    error "pml.yaml non trouvé dans le répertoire source"
    exit 1
fi

log "Création de la structure pml_tools..."

# Création de la structure de répertoires
mkdir -p "$DEST_DIR"/{lib/pmlcore/analyzer,pmlutils/python/analyzer,pmlutils/scripts/{automation,shell}}
mkdir -p "$DEST_DIR"/pmlutils/{output/{doc,reports,temp},logs}

# Copie des fichiers Dart
log "Copie des fichiers Dart..."
if [ -d "$SOURCE_DIR/lib/pmlcore/analyzer" ]; then
    cp -r "$SOURCE_DIR/lib/pmlcore/analyzer/"* "$DEST_DIR/lib/pmlcore/analyzer/"
else
    warn "Répertoire source des analyseurs Dart non trouvé"
fi

# Copie des fichiers Python
log "Copie des fichiers Python..."
if [ -d "$SOURCE_DIR/pmlutils/python/analyzer" ]; then
    cp -r "$SOURCE_DIR/pmlutils/python/analyzer/"* "$DEST_DIR/pmlutils/python/analyzer/"

    # Copie requirements.txt s'il existe
    if [ -f "$SOURCE_DIR/pmlutils/python/requirements.txt" ]; then
        cp "$SOURCE_DIR/pmlutils/python/requirements.txt" "$DEST_DIR/pmlutils/python/"
    fi
else
    warn "Répertoire source des analyseurs Python non trouvé"
fi

# Copie des scripts
log "Copie des scripts..."
if [ -d "$SOURCE_DIR/pmlutils/scripts" ]; then
    # Copie des scripts d'automation
    if [ -d "$SOURCE_DIR/pmlutils/scripts/automation" ]; then
        cp -r "$SOURCE_DIR/pmlutils/scripts/automation/"* "$DEST_DIR/pmlutils/scripts/automation/"
    fi

    # Copie des scripts shell
    if [ -d "$SOURCE_DIR/pmlutils/scripts/shell" ]; then
        cp -r "$SOURCE_DIR/pmlutils/scripts/shell/"* "$DEST_DIR/pmlutils/scripts/shell/"
    fi

    # Copie du script clean.sh
    if [ -f "$SOURCE_DIR/pmlutils/scripts/clean.sh" ]; then
        cp "$SOURCE_DIR/pmlutils/scripts/clean.sh" "$DEST_DIR/pmlutils/scripts/"
    fi
else
    warn "Répertoire source des scripts non trouvé"
fi

# Copie des fichiers de configuration
log "Copie des fichiers de configuration..."
cp "$SOURCE_DIR/pml.yaml" "$DEST_DIR/"
if [ -f "$SOURCE_DIR/run_analysis.sh" ]; then
    cp "$SOURCE_DIR/run_analysis.sh" "$DEST_DIR/"
fi

# Création du README.md
log "Création du README.md..."
cat > "$DEST_DIR/README.md" << 'EOL'
# PML Tools

Outils d'analyse de code pour projets Dart/Flutter.

## Installation

Pour installer les outils dans votre projet Flutter :

```bash
./install_pml_tools.sh /chemin/vers/votre/projet/flutter
```

## Structure

```
pml_tools/
├── lib/pmlcore/       # Analyseurs Dart
├── pmlutils/          # Outils externes
│   ├── python/        # Analyseurs Python
│   └── scripts/       # Scripts d'automatisation
└── pml.yaml          # Configuration
```

## Configuration

Voir pml.yaml pour la configuration détaillée.

## Utilisation

Dans votre projet Flutter après installation :
```bash
./run_analysis.sh
```
EOL

# Configuration des permissions
log "Configuration des permissions..."
find "$DEST_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Copie du script d'installation
log "Création du script d'installation..."
cp "$SOURCE_DIR/install_pml_tools.sh" "$DEST_DIR/" 2>/dev/null || {
    warn "Script d'installation non trouvé, création d'un nouveau..."
    cp "$0" "$DEST_DIR/install_pml_tools.sh"
}
chmod +x "$DEST_DIR/install_pml_tools.sh"

log "Migration terminée!"
log "Structure créée dans: $DEST_DIR"
echo
log "Prochaines étapes:"
echo "1. cd $DEST_DIR"
echo "2. Vérifiez la configuration dans pml.yaml"
echo "3. Testez l'installation avec: ./install_pml_tools.sh /chemin/vers/test/project"