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
