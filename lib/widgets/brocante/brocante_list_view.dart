// ==========================================
// 📋 lib/widgets/brocante/brocante_list_view.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:cobroc/pmltools.dart' show Brocabrac, ManageCobrac;

class BrocanteListView extends StatelessWidget {
  final List<Brocabrac> brocantes;
  final Map<String, int> classementOptimal;
  final Function(Brocabrac) onTap;
  final Function(Brocabrac) onLongPress;
  final Function(Brocabrac) onDoubleTap;
  final Color Function(String, String) getCouleurClassement;

  const BrocanteListView({
    super.key,
    required this.brocantes,
    required this.classementOptimal,
    required this.onTap,
    required this.onLongPress,
    required this.onDoubleTap,
    required this.getCouleurClassement,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: ScrollController(),
        itemCount: brocantes.length,
        itemBuilder: (context, index) {
          Brocabrac brocante = brocantes[index];
          bool estTop10 = _estDansTop10(brocante.eventId);
          int rang = _getRangClassement(brocante.eventId);

          // ========== LOGIQUE DE COULEUR COMPLÈTE ==========
          Color couleurTexte;
          if (brocante.brocEventStatus != 'OK') {
            couleurTexte = Colors.red; // KO = ROUGE
          } else if (estTop10) {
            couleurTexte = getCouleurClassement(brocante.eventId, brocante.brocEventStatus);
          } else if (brocante.brocDejaVu == "New") {
            couleurTexte = Colors.black;
          } else {
            couleurTexte = Colors.blue; // Déjà vue
          }
          // ==================================================

          return InkWell(
            onTap: () => onTap(brocante),
            onLongPress: () => onLongPress(brocante),
            onDoubleTap: () => onDoubleTap(brocante),
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (rang == 1) const Text("🥇 ", style: TextStyle(fontSize: 12)),
                      if (rang == 2) const Text("🥈 ", style: TextStyle(fontSize: 12)),
                      if (rang == 3) const Text("🥉 ", style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          _formatLocalite(brocante),
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Serif',
                            color: couleurTexte,
                            fontWeight: rang <= 3 ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${brocante.brocFromCenter} km - ${brocante.brocStarNbExposants} Exp${_getDensiteAffichage(brocante.brocStarBarycentre)} ${brocante.brocLove}\n${_getClassementAffichage(brocante.eventId, brocante.brocEventStatus)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Serif',
                      color: Colors.black,
                      fontWeight: rang <= 3 ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
              dense: true,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            ),
          );
        },
      ),
    );
  }

  String _formatLocalite(Brocabrac brocante) {
    String postalPrefix = brocante.brocPostal.substring(0, 2);
    String locality = brocante.brocLocality;
    String combined = '$locality ($postalPrefix)';

    if (combined.length > 15) {
      int charsToKeep = 15 - postalPrefix.length - 3;
      if (charsToKeep < 1) charsToKeep = 1;
      return '${locality.substring(0, charsToKeep)}..($postalPrefix)';
    }
    return combined;
  }

  bool _estDansTop10(String eventId) {
    int? rang = classementOptimal[eventId];
    return rang != null && rang <= 10;
  }

  int _getRangClassement(String eventId) {
    return classementOptimal[eventId] ?? 999;
  }

  String _getClassementAffichage(String eventId, String status) {
    if (status != 'OK') return 'Statut: $status';

    int? rang = classementOptimal[eventId];
    if (rang == null || rang > 10) return '';

    if (rang == 1) return '🥇 1er';
    if (rang == 2) return '🥈 2ème';
    if (rang == 3) return '🥉 3ème';
    if (rang <= 10) return '$rangème';

    return '';
  }

  String _getDensiteAffichage(String densiteStr) {
    int densiteValue = int.tryParse(densiteStr) ?? 0;
    if (densiteValue > 0) return ' - D:$densiteStr';
    return '';
  }
}