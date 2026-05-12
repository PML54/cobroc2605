import 'dart:async';

import 'package:cobroc/communestchinos.dart';
import 'package:cobroc/departements.dart';
import 'package:cobroc/detailedBrocante.dart';
import 'package:cobroc/diverspml.dart' show jours, mois;
import 'package:cobroc/historibroc.dart' show Historic, listHistoric;
import 'package:cobroc/monplan.dart';
import 'package:cobroc/networking.dart' show NetworkHelper;
import 'package:cobroc/pmltools.dart' show Brocabrac, GoToMarket, ManageCobrac;
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ========== IMPORTS DES SERVICES ==========
import 'package:cobroc/services/geo_service.dart';
import 'package:cobroc/services/scoring_service.dart';
import 'package:cobroc/services/filter_service.dart';
import 'package:cobroc/services/date_service.dart';
import 'package:cobroc/services/holiday_service.dart';
import 'package:cobroc/services/location_service.dart';
import 'package:cobroc/services/storage_service.dart';
import 'package:cobroc/models/filtre_exposants.dart';
import 'package:cobroc/widgets/brocante/rayon_dialog.dart';

// Ajouter après les autres imports de widgets
import 'package:cobroc/widgets/brocante/brocante_list_view.dart';
import 'package:cobroc/widgets/brocante/brocante_list_reduce.dart';
// ==========================================

class ManagerPML extends StatefulWidget {
  static const String id = 'managerpml';

  const ManagerPML({super.key});

  @override
  _ManagerPMLState createState() => _ManagerPMLState();
}

class _ManagerPMLState extends State<ManagerPML> {
  // Index statiques construits une seule fois depuis les données statiques
  static final Map<String, Commune> _communeIndex = () {
    final map = <String, Commune>{};
    for (final c in listCommunes) {
      map.putIfAbsent(c.ville, () => c);
    }
    return map;
  }();

  static final Set<String> _historicIndex = {
    for (final h in listHistoric) h.villeNormalized
  };

  // ========== SERVICE DE SCORING ==========
  late ScoringService scoringService;
  late LocationService locationService;

  // ========================================

  // Variables GPS
  double? latitudeGPS;
  double? longitudeGPS;
  String? departementGPS;
  List<int> departementsGPS = [];
  bool isLoadingGPS = false;

  // Variables pour les filtres
  FiltreCategorieExposants filtreExposantsActif = FiltreCategorieExposants.tous;
  bool afficherSeulementHistorique = false;

  var versionNum = '250626-1000';
  var pifoMetre = 1.27;
  int nbStepAsync = 0;
  String dateSelected = "2026-05-10";
  String debutHttps = "https://brocabrac.fr/recherche?ou=";
  String finHttps = "&c=bro,vgr,bra&d= ";
  String dimancheInitial = "2024-10-13";
  late DateTime nowInit;
  late DateTime nowActif;
  late DateTime _brocanteDay; // référence exclusive ← → > < (non affectée par +1/-1)
  var secureHistory = 1;
  List<Brocabrac> brocanteBrocabrac = [];
  List<Brocabrac> brocanteBrocabracBis = [];

  double latitudeRef = 0.0;
  double longitudeRef = 0.0;
  double latitudeSelect = 49.03425;
  double longitudeSelect = 2.0913;
  double latitudeLarris = 49.03425;
  double longitudeLarris = 2.0913;
  double latitudePortbail = 49.333;
  double longitudePortbail = -1.7;
  double latitudeLoon = 51.00468727;
  double longitudeLoon = 2.10978637964;

  double rayonBarycentre = 20.0;
  Color colorKO = Colors.red;
  Color colorOK = Colors.green;
  Color colorBROC = Colors.grey;
  Color colorMAISON = Colors.grey;
  bool _vgToggle = true; // true = bouton affiche VG (action VG au prochain tap)
  String copieColler = "";

  DateTime now = DateTime.now();
  int rayonDensite = 12;
  Map<String, int> classementOptimal = {};

  Color colorTop1 = Colors.amber.shade700;
  Color colorTop2 = Colors.grey.shade400;
  Color colorTop3 = const Color(0xFFCD7F32);

  double poidExposants = 30.0;
  double poidDensite = 25.0;
  double poidRevenu = 20.0;
  double poidHistorique = 25.0;
  bool inclureDistance = true;

  static const String appVersion = 'Vers 260512 20:20';

  final cobracIconSize = 20.0;
  int nbBrocabrac = 0;
  int nbBrocOK = 0;
  int maxStepAsync = 6;
  List fullMaster = [];
  var centralCommune = "";
  var centraleventId = "";
  List<int> MonCoinPortbail = [50, 14, 22, 29, 61, 53, 76];
  List<int> MonCoinLarris = [27, 77, 95, 60, 78, 92, 91, 93, 94, 76];
  List<int> MonCoinLoon = [62, 59, 80, 60, 2];
  List<int> MonCoin = [27, 77, 95, 60, 78, 92, 91, 93, 94, 76];
  int lieuActuel = 0;

  ConfigTrajet configTrajet = ConfigTrajet(8, 1, 2, []);

  // ========== MÉTHODES DE FILTRAGE UTILISANT FilterService ==========

  void _showFiltreExposantsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtrer par exposants'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: FiltreCategorieExposants.values.map((filtre) {
              return _buildFiltreOption(
                  FilterService.getLabelFiltre(filtre), filtre);
            }).toList(),
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltreOption(String label, FiltreCategorieExposants valeur) {
    return ListTile(
      title: Text(label),
      leading: Radio<FiltreCategorieExposants>(
        value: valeur,
        groupValue: filtreExposantsActif,
        onChanged: (FiltreCategorieExposants? value) {
          setState(() {
            filtreExposantsActif = value!;
          });
          Navigator.of(context).pop();
        },
      ),
      onTap: () {
        setState(() {
          filtreExposantsActif = valeur;
        });
        Navigator.of(context).pop();
      },
    );
  }

  Color _getCouleurFiltreExposants() {
    return filtreExposantsActif == FiltreCategorieExposants.tous
        ? Colors.white
        : Colors.amber;
  }

  // ===================================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(40.0),
            child: AppBar(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Row(
                children: [
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.map),
                      iconSize: cobracIconSize,
                      color: Colors.deepPurple,
                      tooltip: 'Carte des Brocantes',
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        computeDense(rayonDensite);
                        await (Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MonPlan(),
                            settings: RouteSettings(
                              arguments: brocanteBrocabrac,
                            ),
                          ),
                        ));
                        setState(() {});
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          if (_vgToggle) {
                            setState(() {
                              colorMAISON = colorKO;
                              colorBROC = colorOK;
                              _vgToggle = false;
                            });
                            finHttps = "&c=bro,vgr,bra&d= ";
                          } else {
                            setState(() {
                              colorMAISON = colorOK;
                              colorBROC = colorKO;
                              _vgToggle = true;
                            });
                            finHttps = "&c=vma&d= ";
                          }
                          nbStepAsync = 0;
                          readBrocabrac();
                        },
                        child: Text(_vgToggle ? 'VG' : 'VM',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.map_outlined),
                      iconSize: cobracIconSize,
                      color: Colors.white,
                      tooltip: 'France',
                      padding: EdgeInsets.zero,
                      onPressed: () => callCobrac(context),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.group),
                          if (filtreExposantsActif !=
                              FiltreCategorieExposants.tous)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      iconSize: cobracIconSize,
                      color: _getCouleurFiltreExposants(),
                      tooltip: 'Filtrer par exposants',
                      padding: EdgeInsets.zero,
                      onPressed: _showFiltreExposantsDialog,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      iconSize: cobracIconSize,
                      color: Colors.orange,
                      tooltip: 'Paramètres densité: ${rayonDensite}km',
                      padding: EdgeInsets.zero,
                      onPressed: _showRayonDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: Colors.blue.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(appVersion),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        child: Text(
                          '$nbBrocOK',
                          style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // -1 jour
                      IconButton(
                        icon: const Icon(Icons.exposure_minus_1_outlined),
                        iconSize: cobracIconSize,
                        color: Colors.white,
                        tooltip: '-1 Jour',
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          nbStepAsync = 0;
                          nbBrocabrac = 0;
                          setState(() {
                            nowActif =
                                nowActif.subtract(const Duration(days: 1));
                                          dateSelected = DateService.dateToString(nowActif);
                          });
                          readBrocabrac();
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateService.formatDateBrocante(
                            dateSelected, jours, mois),
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // +1 jour
                      IconButton(
                        icon: const Icon(Icons.plus_one_outlined),
                        iconSize: cobracIconSize,
                        color: Colors.white,
                        tooltip: '+1 Jour',
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          nbStepAsync = 0;
                          nbBrocabrac = 0;
                          setState(() {
                            nowActif = nowActif.add(const Duration(days: 1));
                                          dateSelected = DateService.dateToString(nowActif);
                          });
                          readBrocabrac();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                      children: <Widget>[getListView(), getListViewReduce()]),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SizedBox(
              height: 52,
              child: Row(
                children: <Widget>[
                  // ← boucle semaine précédent
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_outlined),
                      iconSize: 32,
                      color: Colors.blue,
                      tooltip: 'Précédent (boucle semaine)',
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        nbStepAsync = 0;
                        nbBrocabrac = 0;
                        setState(() {
                          _brocanteDay = HolidayService.prevBrocanteDayInWeek(
                              _brocanteDay);
                          nowActif = _brocanteDay;
                                      dateSelected = DateService.dateToString(nowActif);
                        });
                        readBrocabrac();
                      },
                    ),
                  ),
                  // → boucle semaine suivant
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_outlined),
                      iconSize: 32,
                      color: Colors.deepOrange,
                      tooltip: 'Suivant (boucle semaine)',
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        nbStepAsync = 0;
                        nbBrocabrac = 0;
                        setState(() {
                          _brocanteDay = HolidayService.nextBrocanteDayInWeek(
                              _brocanteDay);
                          nowActif = _brocanteDay;
                                      dateSelected = DateService.dateToString(nowActif);
                        });
                        readBrocabrac();
                      },
                    ),
                  ),
                  // 📋 copier-coller
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.copy_all),
                      iconSize: 28,
                      color: Colors.deepOrange,
                      tooltip: 'Copy/Paste',
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        copyInfos();
                        Clipboard.setData(ClipboardData(text: copieColler));
                        setState(() {});
                      },
                    ),
                  ),
                  // > suivant inter-semaines
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      iconSize: 32,
                      color: Colors.deepOrange,
                      tooltip: 'Suivant (Sam/Dim/Férié)',
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        nbStepAsync = 0;
                        nbBrocabrac = 0;
                        setState(() {
                          nowActif = HolidayService.nextBrocanteDay(nowActif);
                                      dateSelected = DateService.dateToString(nowActif);
                        });
                        readBrocabrac();
                      },
                    ),
                  ),
                  // < précédent inter-semaines
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_outlined),
                      iconSize: 32,
                      color: Colors.blue,
                      tooltip: 'Précédent (Sam/Dim/Férié)',
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        nbStepAsync = 0;
                        nbBrocabrac = 0;
                        setState(() {
                          nowActif = HolidayService.prevBrocanteDay(
                              nowActif, DateTime.now());
                                      dateSelected = DateService.dateToString(nowActif);
                        });
                        readBrocabrac();
                      },
                    ),
                  ),
                ],
              ))),
    );
  }

  // ========== MÉTHODES UTILISANT ScoringService ==========

  void calculerToutesLesNotes() {
    classementOptimal = scoringService.calculerTousLesClassements(
      brocanteBrocabrac,
      isInHistoric,
    );
  }

  // =======================================================

  Future<void> callCobrac(BuildContext context) async {
    final result = await Navigator.push<ConfigTrajet>(
      context,
      MaterialPageRoute(builder: (context) => const FranceDepartmentSelector()),
    );

    if (result != null) {
      setState(() {
        configTrajet = result;
        MonCoin.clear();
        MonCoin.addAll(configTrajet.tripSelected);
        nbStepAsync = 0;
      });
      _saveMonCoin(MonCoin);
      readBrocabrac();
    }
  }

  void changerLieuStandard() {
    setState(() {
      lieuActuel = (lieuActuel + 1) % 4;

      switch (lieuActuel) {
        case 0:
          MonCoin.clear();
          MonCoin.addAll(MonCoinLarris);
          latitudeSelect = latitudeLarris;
          longitudeSelect = longitudeLarris;
          latitudeRef = latitudeLarris;
          longitudeRef = longitudeLarris;
          break;
        case 1:
          MonCoin.clear();
          MonCoin.addAll(MonCoinPortbail);
          latitudeSelect = latitudePortbail;
          longitudeSelect = longitudePortbail;
          latitudeRef = latitudePortbail;
          longitudeRef = longitudePortbail;
          break;
        case 2:
          MonCoin.clear();
          MonCoin.addAll(MonCoinLoon);
          latitudeSelect = latitudeLoon;
          longitudeSelect = longitudeLoon;
          latitudeRef = latitudeLoon;
          longitudeRef = longitudeLoon;
          break;
        case 3:
          if (latitudeGPS != null && longitudeGPS != null) {
            _appliquerLieuGPS();
          } else {
            _obtenirPositionGPS().then((_) {
              if (latitudeGPS != null) {
                _appliquerLieuGPS();
              }
            });
          }
          break;
      }

      _saveLieuActuel(lieuActuel);

      if (lieuActuel != 3 ||
          (latitudeGPS != null && departementsGPS.isNotEmpty)) {
        nbStepAsync = 0;
        readBrocabrac();
      }
    });
  }

  void completeInfosPlus() {
    for (Brocabrac _brocky in brocanteBrocabrac) {
      final thatVille = _brocky.brocLocality;
      _brocky.brocDejaVu = isInHistoric(thatVille) ? "" : "New";
      _brocky.revenu = 0;
      final commune = _communeIndex[thatVille];
      if (commune != null) {
        _brocky.revenu = commune.revenu.toInt();
        final rev = _brocky.revenu;
        _brocky.brocStarRevenu = rev >= 30000 ? "5"
            : rev > 25000 ? "4"
            : rev > 20000 ? "3"
            : rev > 15000 ? "2"
            : rev > 10000 ? "1"
            : "0";
      }
    }

    for (Brocabrac _brocky in brocanteBrocabrac) {
      _brocky.brocStarNbExposants = "0";
      if (_brocky.brocNbExposants == "Moins de 50")
        _brocky.brocStarNbExposants = "25";
      if (_brocky.brocNbExposants == "De 50 à 100")
        _brocky.brocStarNbExposants = "75";
      if (_brocky.brocNbExposants == "De 100 à 200")
        _brocky.brocStarNbExposants = "150";
      if (_brocky.brocNbExposants == "De 200 à 300")
        _brocky.brocStarNbExposants = "250";
      if (_brocky.brocNbExposants == "Plus de 300")
        _brocky.brocStarNbExposants = "300";
    }

    int nbInside = -1;
    for (Brocabrac _brocky in brocanteBrocabrac) {
      var latitudeFrom = _brocky.brocLatitude;
      var longitudeFrom = _brocky.brocLongitude;

      nbInside = -1;
      for (Brocabrac _brocky2 in brocanteBrocabrac) {
        var latitudeTo = _brocky2.brocLatitude;
        var longitudeTo = _brocky2.brocLongitude;
        double bricolo = GeoService.distanceInKmBetweenEarthCoordinates(
            latitudeFrom, longitudeFrom, latitudeTo, longitudeTo);
        int initialdist = (bricolo * pifoMetre).round();
        if (initialdist < rayonBarycentre) nbInside++;
      }
      _brocky.brocInside = nbInside;
    }
  }

  void computeDense(int denseRayon) {
    for (Brocabrac _brocky in brocanteBrocabrac) {
      if (_brocky.brocEventStatus == 'OK') {
        var latitudeFrom = _brocky.brocLatitude;
        var longitudeFrom = _brocky.brocLongitude;

        int nbdens = 0;

        for (Brocabrac _brocky2 in brocanteBrocabrac) {
          if (_brocky2.brocEventStatus == 'OK' && _brocky != _brocky2) {
            double bricolo = GeoService.distanceInKmBetweenEarthCoordinates(
                latitudeFrom,
                longitudeFrom,
                _brocky2.brocLatitude,
                _brocky2.brocLongitude);
            int initialdist = (bricolo * pifoMetre).round();
            if (initialdist > 1 && initialdist <= denseRayon) nbdens++;
          }
        }

        _brocky.brocStarBarycentre = nbdens.toString();
      }
    }
    setState(() {});
  }

  void computeNewDistance() {
    for (Brocabrac _brocky in brocanteBrocabrac) {
      var latitudeTo = _brocky.brocLatitude;
      var longitudeTo = _brocky.brocLongitude;
      double bricolo = GeoService.distanceInKmBetweenEarthCoordinates(
          latitudeRef, longitudeRef, latitudeTo, longitudeTo);
      int initialdist = (bricolo * pifoMetre).round();
      _brocky.brocFromCenter = initialdist;
    }

    completeInfosPlus();
    brocanteBrocabrac
        .sort((a, b) => a.brocFromCenter.compareTo(b.brocFromCenter));

    int thatMaster = 0;
    for (Brocabrac _brocky in brocanteBrocabrac) {
      _brocky.brocMaster = ++thatMaster;
    }
    setState(() {});
  }

  void computeNewDistanceFromSelect() {
    for (Brocabrac _brocky in brocanteBrocabrac) {
      final latitudeTo = _brocky.brocLatitude;
      final longitudeTo = _brocky.brocLongitude;
      final bricolo = GeoService.distanceInKmBetweenEarthCoordinates(
          latitudeSelect, longitudeSelect, latitudeTo, longitudeTo);
      final initialdist = (bricolo * pifoMetre).round();
      _brocky.brocFromSelect = initialdist;
    }

    brocanteBrocabracBis = List.from(brocanteBrocabrac);
    brocanteBrocabracBis
        .sort((a, b) => a.brocFromSelect.compareTo(b.brocFromSelect));

    setState(() {
      nbBrocOK = brocanteBrocabracBis
          .where((brocabrac) => brocabrac.brocEventStatus == 'OK')
          .length;
      brocanteBrocabracBis
          .retainWhere((brocabrac) => brocabrac.brocEventStatus == 'OK');
    });

    nbBrocOK = 0;
    for (var brocabrac in brocanteBrocabracBis) {
      setState(() {
        nbBrocOK++;
      });
      brocabrac.brocMaster = nbBrocOK;
    }
  }

  void copyInfos() {
    copieColler = "";
    copieColler =
        "Localité;Code Postal;Km de  Pontoise;km depuis Choix;Nom;Organisateur;Exposants;Adresse;Date;Revenu;Concentration;Déjà Faite;Statut;Like;Description\n";
    for (Brocabrac _brocky in brocanteBrocabrac) {
      copieColler = "$copieColler${_brocky.brocLocality};";
      copieColler = "$copieColler${_brocky.brocPostal};";
      copieColler = "$copieColler${_brocky.brocFromCenter};";
      copieColler = "$copieColler${_brocky.brocFromSelect};";
      copieColler = "$copieColler${_brocky.brocName.replaceAll(';', ' ')};";
      String prov = _brocky.brocOrganizer.replaceAll(';', ' ');
      prov = prov.replaceAll('"', ' ');
      copieColler = "$copieColler$prov;";
      copieColler = "$copieColler${_brocky.brocStarNbExposants};";
      copieColler = "$copieColler${_brocky.brocStreet.replaceAll(';', ' ')};";
      copieColler = "$copieColler${_brocky.brocStartDate};";
      copieColler = "$copieColler${_brocky.brocStarRevenu};";
      copieColler = "$copieColler${_brocky.brocStarBarycentre};";
      copieColler = "$copieColler${_brocky.brocDejaVu};";
      copieColler = "$copieColler${_brocky.brocEventStatus};";
      copieColler = "$copieColler${_brocky.brocLove};";
      copieColler =
          "$copieColler${_brocky.brocDescription.replaceAll('\n', ' ')}\n";
    }
  }

  Color getCouleurClassement(String eventId, String status) {
    if (status != 'OK') return colorKO;

    int? rang = classementOptimal[eventId];
    if (rang == null) return colorOK;

    switch (rang) {
      case 1:
        return colorTop1;
      case 2:
        return colorTop2;
      case 3:
        return colorTop3;
      default:
        return colorOK;
    }
  }

  Brocabrac getCurrentBrocabrac(String centralCommune, String identif) {
    late Brocabrac rocky;
    for (Brocabrac _brocky in brocanteBrocabrac) {
      if (_brocky.brocLocality == centralCommune &&
          _brocky.eventId == identif) {
        return (_brocky);
      }
      rocky = _brocky;
    }
    return (rocky);
  }

  void getCurrentCommmune() {
    for (Brocabrac _brocky in brocanteBrocabrac) {
      if (_brocky.brocLocality == centralCommune) {
        latitudeSelect = _brocky.brocLatitude;
        longitudeSelect = _brocky.brocLongitude;
        break;
      }
    }
  }

  Future<String> getInfoBrocabrac(Uri bigUrl) async {
    NetworkHelper networkHelper = NetworkHelper();
    await networkHelper.getDataBrocabrac(bigUrl, fullMaster);

    for (Brocabrac _brocky in fullMaster) {
      nbBrocabrac++;
      _brocky.setbrocMaster(nbBrocabrac);
      brocanteBrocabrac.add(_brocky);
    }

    computeNewDistance();
    computeDense(rayonDensite);
    calculerToutesLesNotes();

    fullMaster.clear();

    setState(() {
      nbStepAsync++;
    });

    if (nbStepAsync == maxStepAsync + 1) nbStepAsync = 0;

    return ("OK");
  }

  String getLieuActuelNom() {
    switch (lieuActuel) {
      case 0:
        return 'Larris';
      case 1:
        return 'Portbail';
      case 2:
        return 'Loon';
      case 3:
        if (departementGPS != null) {
          return 'GPS ($departementGPS)';
        } else {
          return 'GPS (...)';
        }
      default:
        return 'Larris';
    }
  }

  Future<void> _obtenirPositionGPS() async {
    setState(() {
      isLoadingGPS = true;
    });

    try {
      final locationData = await locationService.obtenirPositionGPS();

      if (locationData != null) {
        setState(() {
          latitudeGPS = locationData.latitude;
          longitudeGPS = locationData.longitude;
          departementGPS = locationData.departement;
          departementsGPS = locationData.departementsProches;

          if (lieuActuel == 3) {
            _appliquerLieuGPS();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur GPS: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingGPS = false;
      });
    }
  }

  void _appliquerLieuGPS() {
    if (latitudeGPS != null &&
        longitudeGPS != null &&
        departementsGPS.isNotEmpty) {
      MonCoin.clear();
      MonCoin.addAll(departementsGPS);
      latitudeSelect = latitudeGPS!;
      longitudeSelect = longitudeGPS!;
      latitudeRef = latitudeGPS!;
      longitudeRef = longitudeGPS!;
      _saveMonCoin(MonCoin);
    }
  }

  Widget getListView() {
    List<Brocabrac> brocantesAffichees = FilterService.appliquerFiltres(
      brocantes: brocanteBrocabrac,
      filtreExposants: filtreExposantsActif,
      afficherHistorique: afficherSeulementHistorique,
      isInHistoric: isInHistoric,
    );

    return BrocanteListView(
      brocantes: brocantesAffichees,
      classementOptimal: classementOptimal,
      getCouleurClassement: getCouleurClassement,
      onTap: (brocante) {
        setState(() {
          if (brocante.brocEventStatus == "OK") {
            centralCommune = brocante.brocLocality;
            centraleventId = brocante.eventId;
            getCurrentCommmune();
            computeNewDistanceFromSelect();
          }
        });
      },
      onLongPress: (brocante) {
        setState(() {
          centraleventId = brocante.eventId;
          centralCommune = brocante.brocLocality;
        });
        Brocabrac thisBrocabrac =
            getCurrentBrocabrac(centralCommune, centraleventId);
        ManageCobrac manageCobrac =
            ManageCobrac(brocanteBrocabrac, thisBrocabrac);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DetailBroc(),
            settings: RouteSettings(arguments: manageCobrac),
          ),
        );
      },
      onDoubleTap: (brocante) {
        setState(() {
          if (brocante.brocEventStatus == "OK") {
            if (brocante.brocLove == "❤") {
              // ✅ CŒUR ROUGE
              brocante.brocLove = "";
            } else {
              brocante.brocLove = "❤"; // ✅ CŒUR ROUGE
            }
          }
        });
      },
    );
  }

  Widget getListViewReduce() {
    List<Brocabrac> brocantesAffiches = FilterService.appliquerFiltres(
      brocantes: brocanteBrocabracBis,
      filtreExposants: filtreExposantsActif,
      afficherHistorique: afficherSeulementHistorique,
      isInHistoric: isInHistoric,
    );

    return BrocanteListReduce(
      brocantes: brocantesAffiches,
      isInHistoric: isInHistoric,
      secureHistory: secureHistory,
    );
  }

  @override
  void initState() {
    super.initState();

    // ========== INITIALISER LES SERVICES ==========
    locationService = LocationService();
    // ==============================================

    Future.wait([
      _loadLieuActuel(),
      _loadAllParametres(),
      _loadMonCoin(),
    ]).then((_) {
      // ========== INITIALISER LE SERVICE DE SCORING APRÈS CHARGEMENT DES PARAMÈTRES ==========
      scoringService = ScoringService(
        rayonDensite: rayonDensite,
        poidExposants: poidExposants,
        poidDensite: poidDensite,
        poidRevenu: poidRevenu,
        poidHistorique: poidHistorique,
        inclureDistance: inclureDistance,
      );
      // ========================================================================================

      // GPS au démarrage : coordonnées seulement, sans écraser MonCoin
      _obtenirPositionGPS().then((_) {
        if (latitudeGPS != null && longitudeGPS != null) {
          setState(() {
            latitudeSelect = latitudeGPS!;
            longitudeSelect = longitudeGPS!;
            latitudeRef = latitudeGPS!;
            longitudeRef = longitudeGPS!;
          });
        }
      });

      dateSelected = DateService.getDateNextDimanche();
      dimancheInitial = dateSelected;
      DateTime nowTemp = DateTime.now();
      nowInit = nowTemp.add(Duration(days: 7 - nowTemp.weekday));
      nowActif = nowInit;
      _brocanteDay = nowActif;
      centralCommune = versionNum;

      if (lieuActuel == 0) {
        latitudeRef = latitudeLarris;
        longitudeRef = longitudeLarris;
        latitudeSelect = latitudeRef;
        longitudeSelect = longitudeRef;
      }

      nbBrocabrac = 0;
      readBrocabrac();
    });
  }

  bool isInHistoric(String thatVille) {
    return _historicIndex.contains(normalizeString(thatVille));
  }

  String normalizeString(String str) {
    String withoutDiacritics = removeDiacritics(str);
    return withoutDiacritics.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
  }

  void readBrocabrac() {
    DateTime dt = DateTime.parse(dateSelected);
    final todayDate = DateTime(now.year, now.month, now.day);

    if (dt.isBefore(todayDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date dans le passé — choisissez une date à venir.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (nbStepAsync > 0) return;
    nbBrocOK = 0;
    nbBrocabrac = 0;
    brocanteBrocabrac.clear();
    brocanteBrocabracBis.clear();
    classementOptimal.clear();

    nbStepAsync = 1;

    for (int dipart in MonCoin) {
      String quelCoin = dipart.toString();
      String paramHttps = debutHttps + quelCoin + finHttps + dateSelected;
      Uri myUrl = Uri.parse(paramHttps);

      getInfoBrocabrac(myUrl).then((_) {
        updateNbBrocOK();
      });
    }
  }

  void updateNbBrocOK() {
    setState(() {
      nbBrocOK = brocanteBrocabrac
          .where((brocante) => brocante.brocEventStatus == 'OK')
          .length;
    });
  }

  void _appliquerLieuSansLecture() {
    switch (lieuActuel) {
      case 0:
        MonCoin.clear();
        MonCoin.addAll(MonCoinLarris);
        latitudeSelect = latitudeLarris;
        longitudeSelect = longitudeLarris;
        latitudeRef = latitudeLarris;
        longitudeRef = longitudeLarris;
        break;
      case 1:
        MonCoin.clear();
        MonCoin.addAll(MonCoinPortbail);
        latitudeSelect = latitudePortbail;
        longitudeSelect = longitudePortbail;
        latitudeRef = latitudePortbail;
        longitudeRef = longitudePortbail;
        break;
      case 2:
        MonCoin.clear();
        MonCoin.addAll(MonCoinLoon);
        latitudeSelect = latitudeLoon;
        longitudeSelect = longitudeLoon;
        latitudeRef = latitudeLoon;
        longitudeRef = longitudeLoon;
        break;
      case 3:
        if (latitudeGPS != null &&
            longitudeGPS != null &&
            departementsGPS.isNotEmpty) {
          _appliquerLieuGPS();
        }
        break;
    }
  }

  Future<void> _loadAllParametres() async {
    final params = await StorageService.loadParameters();
    setState(() {
      rayonDensite = params.rayonDensite;
      poidExposants = params.poidExposants;
      poidDensite = params.poidDensite;
      poidRevenu = params.poidRevenu;
      poidHistorique = params.poidHistorique;
      inclureDistance = params.inclureDistance;
    });
  }

  Future<void> _loadLieuActuel() async {
    final savedLieu = await StorageService.loadLieuActuel();
    if (savedLieu >= 0 && savedLieu <= 3) {
      setState(() {
        lieuActuel = savedLieu;
      });
      _appliquerLieuSansLecture();
    }
  }

  Future<void> _saveAllParametres() async {
    await StorageService.saveParameters(AppParameters(
      rayonDensite: rayonDensite,
      poidExposants: poidExposants,
      poidDensite: poidDensite,
      poidRevenu: poidRevenu,
      poidHistorique: poidHistorique,
      inclureDistance: inclureDistance,
    ));
  }

  Future<void> _saveLieuActuel(int lieu) async {
    await StorageService.saveLieuActuel(lieu);
  }

  Future<void> _saveMonCoin(List<int> deps) async {
    await StorageService.saveMonCoin(deps);
  }

  Future<void> _loadMonCoin() async {
    final deps = await StorageService.loadMonCoin();
    if (deps.isNotEmpty) {
      setState(() {
        MonCoin.clear();
        MonCoin.addAll(deps);
      });
    }
  }

  // ========== DIALOG SIMPLIFIÉ UTILISANT RayonDialog ==========
  void _showRayonDialog() {
    final parametresActuels = AppParameters(
      rayonDensite: rayonDensite,
      poidExposants: poidExposants,
      poidDensite: poidDensite,
      poidRevenu: poidRevenu,
      poidHistorique: poidHistorique,
      inclureDistance: inclureDistance,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RayonDialog(
          parametresInitiaux: parametresActuels,
          onValidate: (nouveauxParams) {
            setState(() {
              rayonDensite = nouveauxParams.rayonDensite;
              poidExposants = nouveauxParams.poidExposants;
              poidDensite = nouveauxParams.poidDensite;
              poidRevenu = nouveauxParams.poidRevenu;
              poidHistorique = nouveauxParams.poidHistorique;
              inclureDistance = nouveauxParams.inclureDistance;

              // Réinitialiser le service de scoring avec les nouveaux paramètres
              scoringService = ScoringService(
                rayonDensite: rayonDensite,
                poidExposants: poidExposants,
                poidDensite: poidDensite,
                poidRevenu: poidRevenu,
                poidHistorique: poidHistorique,
                inclureDistance: inclureDistance,
              );

              computeDense(rayonDensite);
              calculerToutesLesNotes();
            });

            _saveAllParametres();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paramètres mis à jour !'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
// =============================================================
}
