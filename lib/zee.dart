
import 'package:cobroc/historibroc.dart' show Historic, listHistoric;
import 'package:cobroc/pmltools.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

double safeAverage(Iterable<num> numbers) {
  if (numbers.isEmpty) return 0;
  double sum = numbers.fold(0.0, (prev, element) => prev + element.toDouble());
  return sum / numbers.length;
}
String findMostRecentDate(List<Historic> entries) {
  if (entries.isEmpty) return "Aucune date";
  // Trier les entrées par date (du plus récent au plus ancien)
  entries.sort((a, b) {
    // Convertir les dates string en objets DateTime pour la comparaison
    DateTime dateA = DateFormat("dd/MM/yyyy").parse(a.histDate);
    DateTime dateB = DateFormat("dd/MM/yyyy").parse(b.histDate);
    return dateB.compareTo(dateA);
  });

  // Retourner la date la plus récente
  return entries.first.histDate;
}


Map<String, dynamic> analyzeBrocante(String ville) {
  var cityEntries = listHistoric.where((h) => h.histVille.toUpperCase() == ville.toUpperCase()).toList();

  if (cityEntries.isEmpty) {
    return {'error': 'Aucune donnée historique trouvée pour cette ville'};
  }

  double avgQuality = safeAverage(cityEntries.map((e) => e.histGood).where((e) => e > 0));
  double avgSize = safeAverage(cityEntries.map((e) => e.histNbExpo).where((e) => e > 0));
  double avgSpending = safeAverage(cityEntries.map((e) => (e.histPmlDep + e.histFraDep + e.histMaisonDep)).where((e) => e > 0));
  int frequency = cityEntries.length;
  String lastDate = findMostRecentDate(cityEntries);

  if (avgQuality == 0 && avgSize == 0 && avgSpending == 0) {
    return {'error': 'Données insuffisantes pour une analyse complète'};
  }

  var allComments = cityEntries.map((e) => "${e.histAvis} ${e.histDetail}").join(" ");
  var positiveWords = ['bon', 'bien', 'super', 'intéressant', 'qualité'];
  var negativeWords = ['mauvais', 'pauvre', 'décevant', 'éviter', 'rien'];
  int positiveCount = positiveWords.fold(0, (sum, word) => sum + allComments.toLowerCase().split(word).length - 1);
  int negativeCount = negativeWords.fold(0, (sum, word) => sum + allComments.toLowerCase().split(word).length - 1);

  int qualityScore = (avgQuality / 5 * 20).round();
  int sizeScore = (min(avgSize / 300, 1) * 20).round();
  int spendingScore = (min(avgSpending / 100, 1) * 20).round();
  int consistencyScore = (min(frequency / 10, 1) * 20).round();
  int commentScore = positiveCount > negativeCount ? 16 : (positiveCount < negativeCount ? 8 : 12);

  int overallScore = ((qualityScore + sizeScore + spendingScore + consistencyScore + commentScore) / 5).round();

  return {
    'ville': ville,
    'qualité': '$qualityScore/20',
    'taille': '$sizeScore/20',
    'dernière Visite': lastDate,  // Ajout de la dernière date
    'potentiel_achat': '$spendingScore/20',
    // 'constance': '$consistencyScore/20',
    'commentaires': '$commentScore/20',
    'note_globale': '$overallScore/20',
    'fréquence': frequency,
    'taille_moyenne': '${avgSize.round()} exposants',
    'dépense_moyenne': '${avgSpending.round()}€',
    'commentaires': 'Positifs: $positiveCount, Négatifs: $negativeCount',


  };
}
// Fonction utilitaire pour limiter une valeur
double min(double a, double b) => (a < b) ? a : b;

class DetailBroc extends StatefulWidget {
  const DetailBroc({super.key});

  @override
  _DetailBrocState createState() => _DetailBrocState();
}


class _DetailBrocState extends State<DetailBroc> {
  // Génerer dans google sheets
  String thatbrocType = "";
  String thatbrocLocality = "";
  String thatbrocPostal = "";
  String thatbrocStreet = "";
  double thatbrocLatitude = 0.0;
  double thatbrocLongitude = 0.0;
  String thatbrocEventStatus = "";
  String thatbrocVenueName="";
  String thatbrocOrganizer = "";
  String thatbrocStartDate = "";
  String thatbrocEndDate = "";
  String thatbrocDescription = "";
  String thatbrocNbExposants = "";
  String thatbrocStarBarycentre = "";
  String thatbrocEventId ="";
  int thatbrocDistance = 0;
  Color thatColor = Colors.green;
//_brocky.brocStarBarycentre
  // A recupérer
  double altitude = 0.0;
  double superficie = 0.0;
  double population = 0.0;
  int codeDepartement = 0;
  int codeRegion = 0;
  int thatRevenu = 0;
  int masterBroc = 0;
  int nbPassage = 0;
  late ManageCobrac manageCobrac;
  late Brocabrac thatBrocante;
  List<Brocabrac> allBrocante = [];
  Color colorBrocor = Colors.grey;
  Map<String, dynamic> brocAnalysis = {};

  @override
  Widget build(BuildContext context) {

    if (nbPassage == 0) {
      //PML


      var arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is ManageCobrac) {
        manageCobrac = arguments;

      } else {
        // Traiter le cas où les arguments sont null ou d'un type incorrect.
        // Vous pouvez attribuer une valeur par défaut ou prendre une autre action en conséquence.
      }

      print ("nb Passage= $nbPassage");

      allBrocante = manageCobrac.brocanteBrocabrac;
      thatBrocante = manageCobrac.brocabrac;
      nbPassage = 1;
      masterBroc = thatBrocante.brocMaster -1;
      print ("masterBroc (build)$masterBroc");


    } else {
      thatBrocante = allBrocante[masterBroc];
    }
    readActiveRecord();
    setState(() {


    });
//***********


    //*********************
    return Scaffold(
      appBar:  AppBar(actions: <Widget>[
        Center(
          child: Text(
            "$thatbrocDistance km $thatbrocLocality",
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
        ),

        IconButton(
          icon: const Icon(Icons.arrow_upward),
          iconSize: 25,
          color: masterBroc > 0 ? Colors.red : Colors.grey, // Désactiver si on est à la première ville
          onPressed: () {
            print ("masterBroc=$masterBroc");
            if (masterBroc > 0) {
              bool answer = getPrevRecord();
              if (answer) {
                setState(() {
                  readActiveRecord();
                });
              }
            }
          },
        ),

        IconButton(
            icon: const Icon(Icons.arrow_downward),
            iconSize: 25,
            color: Colors.red,
            tooltip: 'brocabrac',
            onPressed: () {
              bool answer = getNextRecord();
              if (answer == true) {
                setState(() {
                  readActiveRecord();

                  //   mapTripSingle = setSingleMarker();

                });
              } }),
        //
      ]),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              RichText(
                  text: TextSpan(
                      style: TextStyle(color: thatColor, fontSize: 15),
                      text: "$thatbrocPostal  $thatbrocLocality $thatbrocEventStatus")),
            ]),
            Row(children: <Widget>[
              RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      text:  "Identifiant Brocabrac = $thatbrocEventId" )),
            ]),
            Row(children: <Widget>[
              RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 15),
                      text: "Lieu  = $thatbrocVenueName")),
            ]),
            Row(children: <Widget>[
              RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                      text: thatbrocStreet)),
            ]),
            Row(children: <Widget>[
              RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      text: "$thatbrocNbExposants Exposants")),
            ]),
            Row(children: <Widget>[
              RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      text: "Revenu Moyen = $thatRevenu€")),
            ]),
            Row(children: <Widget>[
              RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      text: "Organisateur = $thatbrocOrganizer")),
            ]),
            Row(children: <Widget>[
              RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      text:    "Avec $thatbrocStarBarycentre Brocantes  à moins de 15 km" )),
            ]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: RichText(
                    text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                        text: thatbrocDescription)),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Analyse de la brocante',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (brocAnalysis.isNotEmpty)
                      if (brocAnalysis['error'] != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            brocAnalysis['error'],
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else
                        ...brocAnalysis.entries.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Text(
                            '${entry.key.replaceAll('_', ' ').capitalize()}: ${entry.value}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ))
                    else
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Aucune donnée d\'analyse disponible',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),





      ),
    );



  }

  bool getNextRecord() {

    if (masterBroc  >= allBrocante.length-1) return false;
    setState(() {
      masterBroc = masterBroc + 1;
      print ( "masterBroc=$masterBroc");
      print ("allBrocante.length=${allBrocante.length}");
      thatBrocante = allBrocante[masterBroc];
      //  readActiveRecord();
    });
    return (true);
  }


  bool getPrevRecord() {
    if (masterBroc < 0) return false; // Empêcher de descendre en-dessous de 1
    setState(() {
      masterBroc--; // Décrémenter masterBroc directement
      thatBrocante = allBrocante[masterBroc]; // Assurez-vous que l'index correspond correctement
      readActiveRecord(); // Lire l'enregistrement
    });
    return true;
  }

  void readActiveRecord() {
    setState(() {
      thatbrocType = thatBrocante.brocType;
      thatbrocLocality = thatBrocante.brocLocality;
      thatbrocPostal = thatBrocante.brocPostal;
      thatbrocStreet = thatBrocante.brocStreet;
      thatbrocLatitude = thatBrocante.brocLatitude;
      thatbrocLongitude = thatBrocante.brocLongitude;
      thatbrocEventStatus = thatBrocante.brocEventStatus;
      thatbrocOrganizer = thatBrocante.brocOrganizer;
      thatbrocStartDate = thatBrocante.brocStartDate;
      thatbrocEndDate = thatBrocante.brocEndDate;
      thatbrocDescription = thatBrocante.brocDescription;
      thatbrocNbExposants = thatBrocante.brocNbExposants;
      thatbrocDistance = thatBrocante.brocFromCenter;
      thatRevenu = thatBrocante.revenu;
      thatbrocVenueName=thatBrocante.brocVenueName;
      thatbrocStarBarycentre = thatBrocante.brocStarBarycentre;
      thatbrocEventId= thatBrocante.eventId;
      thatColor = Colors.green;
      if (thatbrocEventStatus == "KO") {
        thatColor = Colors.red;
        thatbrocEventStatus = "Brocante Annulée!!";
      } else {
        thatbrocEventStatus = "";
      }
      brocAnalysis = analyzeBrocante(thatbrocLocality);
    });
  }

  GoToMarket setSingleMarker() {
    // Marker  A remettre  A jour
    var markerOrdre = "${thatBrocante.brocFromCenter}km  : ${thatBrocante.brocLocality}";
    List<Marker> allMarkers = [];

    allMarkers.add(Marker(
      markerId: MarkerId(thatBrocante.brocNbExposants),
      draggable: false,
      infoWindow:
      InfoWindow(title: markerOrdre, snippet: thatBrocante.brocStreet),
      onTap: () {},
      position: LatLng(thatBrocante.brocLatitude, thatBrocante.brocLongitude),
    ));

// TODO a mettre ailleurs
    double latitudeLarris = 49.034463;
    double longitudeLarris = 2.090107;

    GoToMarket mapTrip =
    GoToMarket(1, allMarkers, latitudeLarris, longitudeLarris);
    setState(() {
      mapTrip.centerLatitude = thatBrocante.brocLatitude;
      mapTrip.centerLongitude = thatBrocante.brocLongitude;
      mapTrip.tripNbStep = 1;

    });
    return (mapTrip);
  }

}

extension StringExtension on String {
  String capitalize() {
    return split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}

