cd ~/Desktop  # ou le chemin vers votre projet Flutter
cd votre_projet_flutter/lib

# Créer les dossiers
mkdir -p models
mkdir -p services
mkdir -p widgets/brocante

# Créer les fichiers models
touch models/filtre_exposants.dart
touch models/config_lieu.dart

# Créer les fichiers services
touch services/geo_service.dart
touch services/scoring_service.dart
touch services/filter_service.dart
touch services/location_service.dart
touch services/date_service.dart
touch services/storage_service.dart

# Créer les fichiers widgets
touch widgets/brocante/brocante_list_view.dart
touch widgets/brocante/brocante_list_reduce.dart
touch widgets/brocante/rayon_dialog.dart
touch widgets/brocante/filtre_exposants_dialog.dart

# Backup de managerpml.dart
cp managerpml.dart managerpml.dart.backup

echo "✅ Tous les fichiers ont été créés !"
ls -la models/ services/ widgets/brocante/