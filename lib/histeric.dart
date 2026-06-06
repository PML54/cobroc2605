// lib/histeric.dart
// Modified: 260606161500
// Histeric — navigation dans l'historique par commune
// CHANGEMENTS: (1) loadHistorics: remplace normalizeString == par Historic.matchesVille pour match partiel, ligne 51
import 'package:cobroc/historibroc.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';

class Histeric extends StatefulWidget {
  const Histeric({super.key});

  @override
  _HistericState createState() => _HistericState();
}

class _HistericState extends State<Histeric> {
  List<Historic> myHistoric = [];
  Historic? currentHistoric;

  @override
  Widget build(BuildContext context) {
    final String thatCommune = ModalRoute.of(context)?.settings.arguments as String? ?? "";
    if (myHistoric.isEmpty) {
      loadHistorics(thatCommune);
    }

    return Scaffold(
      appBar: buildAppBar(),
      body: currentHistoric == null ? const Center(child: Text("No data available")) : buildHistoricDetails(),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      actions: <Widget>[
        navigationButton(Icons.arrow_back, decrementRecord),
        navigationButton(Icons.laptop, () {}),
        navigationButton(Icons.arrow_forward, incrementRecord),
      ],
    );
  }

  Widget navigationButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      color: Colors.green,
      iconSize: icon == Icons.laptop ? 30.0 : 60.0,
      tooltip: 'Navigate',
      onPressed: onPressed,
    );
  }

  void loadHistorics(String commune) {
    myHistoric = listHistoric
        .where((historic) => Historic.matchesVille(historic.histVille, commune))
        .toList();
    myHistoric.sort((a, b) => b.histCheckDate.compareTo(a.histCheckDate));
    if (myHistoric.isNotEmpty) {
      setState(() => currentHistoric = myHistoric.first);
    }
  }

  void incrementRecord() {
    int currentIndex = myHistoric.indexOf(currentHistoric!);
    if (currentIndex < myHistoric.length - 1) {
      setState(() => currentHistoric = myHistoric[++currentIndex]);
    }
  }

  void decrementRecord() {
    int currentIndex = myHistoric.indexOf(currentHistoric!);
    if (currentIndex > 0) {
      setState(() => currentHistoric = myHistoric[--currentIndex]);
    }
  }

  Widget buildHistoricDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${currentHistoric!.histName} : #${currentHistoric!.histDate}#', style: TextStyle(fontSize: 20, color: getColorByRating(currentHistoric!.histGood))),
          Text('Exposants: <${currentHistoric!.histNbExpo}>', style: const TextStyle(fontSize: 20)),
          Text('Commune: ${currentHistoric!.histVille}', style: TextStyle(fontSize: 18, color: getColorByRating(currentHistoric!.histGood))),
          Text('Adresse: ${currentHistoric!.histAdresse}', style: TextStyle(fontSize: 22, color: getColorByRating(currentHistoric!.histGood))),
          Text('Avis: ${currentHistoric!.histAvis}', style: const TextStyle(fontSize: 18)),
          Text('Détails: ${currentHistoric!.histDetail}', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Color getColorByRating(int rating) {
    switch (rating) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.blue;
      case 4: return Colors.greenAccent;
      default: return Colors.grey;
    }
  }

  String normalizeString(String str) {
    return removeDiacritics(str).toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
  }
}
