// ==========================================
// 📦 lib/services/storage_service.dart
// ==========================================

class AppParameters {
  final int rayonDensite;
  final double poidExposants;
  final double poidDensite;
  final double poidRevenu;
  final double poidHistorique;
  final bool inclureDistance;

  const AppParameters({
    required this.rayonDensite,
    required this.poidExposants,
    required this.poidDensite,
    required this.poidRevenu,
    required this.poidHistorique,
    required this.inclureDistance,
  });

  // Valeurs par défaut (basées sur votre code de juillet)
  factory AppParameters.defaults() {
    return const AppParameters(
      rayonDensite: 12,
      poidExposants: 30.0,
      poidDensite: 25.0,
      poidRevenu: 20.0,
      poidHistorique: 25.0,
      inclureDistance: true,
    );
  }

  // CopyWith pour faciliter les modifications
  AppParameters copyWith({
    int? rayonDensite,
    double? poidExposants,
    double? poidDensite,
    double? poidRevenu,
    double? poidHistorique,
    bool? inclureDistance,
  }) {
    return AppParameters(
      rayonDensite: rayonDensite ?? this.rayonDensite,
      poidExposants: poidExposants ?? this.poidExposants,
      poidDensite: poidDensite ?? this.poidDensite,
      poidRevenu: poidRevenu ?? this.poidRevenu,
      poidHistorique: poidHistorique ?? this.poidHistorique,
      inclureDistance: inclureDistance ?? this.inclureDistance,
    );
  }

  // Conversion en Map pour la sérialisation
  Map<String, dynamic> toMap() {
    return {
      'rayonDensite': rayonDensite,
      'poidExposants': poidExposants,
      'poidDensite': poidDensite,
      'poidRevenu': poidRevenu,
      'poidHistorique': poidHistorique,
      'inclureDistance': inclureDistance,
    };
  }

  // Création depuis un Map
  factory AppParameters.fromMap(Map<String, dynamic> map) {
    return AppParameters(
      rayonDensite: map['rayonDensite'] as int? ?? 12,
      poidExposants: (map['poidExposants'] as num?)?.toDouble() ?? 30.0,
      poidDensite: (map['poidDensite'] as num?)?.toDouble() ?? 25.0,
      poidRevenu: (map['poidRevenu'] as num?)?.toDouble() ?? 20.0,
      poidHistorique: (map['poidHistorique'] as num?)?.toDouble() ?? 25.0,
      inclureDistance: map['inclureDistance'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'AppParameters(rayon: ${rayonDensite}km, exposants: ${poidExposants.round()}%, '
        'densité: ${poidDensite.round()}%, revenu: ${poidRevenu.round()}%, '
        'historique: ${poidHistorique.round()}%, distance: $inclureDistance)';
  }
}