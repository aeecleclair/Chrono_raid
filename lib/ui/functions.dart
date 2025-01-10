import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

Future<List<Map<String,String>>> readJsonEquipes() async {
  final String response = await rootBundle.loadString('assets/Equipes.json');
  final List<dynamic> data = await json.decode(response)["Equipes"];
  final List<Map<String,String>> data2 = data.map(
    (item) => {
    "dossard": item["dossard"] as String, 
    "parcours": item["parcours"] as String,
    }
    ).toList();
  return data2;
}

Future<Map<String, List<String>>> readJsonEpreuves(ravito) async {
  final String response = await rootBundle.loadString('assets/Epreuves.json');
  final d = json.decode(response);
  final Map<String, dynamic> data;
  if (ravito == 'admin') { 
    data = {"Découverte": [], "Sportif": [], "Expert": []};
    for (var r in d.keys) {
      for (var p in ["Découverte", "Sportif", "Expert"]) {
        data[p] = [data[p], d[r]["Epreuves"][p]].expand((x) => x).toList();
      }
    }
  } else {
    data = d[ravito]["Epreuves"];
  }
  final Map<String, List<String>> data2 = Map.fromEntries(
    data.entries
      .where((entry) => entry.key != "CO")
      .map(
        (entry) => MapEntry(
          entry.key,
          List<String>.from(entry.value),
        ),
      ),
  );
  return data2;

}

Future compteEpreuves() async {
  final String response = await rootBundle.loadString('assets/Epreuves.json');
  final d = json.decode(response);
  final Map<String, dynamic> data;
  data = {"Découverte": {}, "Sportif": {}, "Expert": {}};
  for (var r in d.keys) {
    for (var p in ["Découverte", "Sportif", "Expert"]) {
      data[p][r] = d[r]["Epreuves"][p].length;
    }
  }
  return data;
}

Future<List<String>> getRavitos() async {
  final String response = await rootBundle.loadString('assets/Epreuves.json');
  final Map<String, dynamic> data = json.decode(response);
  return List<String>.from(data.keys);
}

String dateToFormat(String date) {
  if (date == '-') {
    return '-';
  }
  else {
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    return isMobile ? DateFormat('dd/MM\nH:m:s').format(DateTime.parse(date)) : DateFormat('dd/MM - H:m:s').format(DateTime.parse(date));
  }
}

Future<bool> isCO(ravito) async{
  final String response = await rootBundle.loadString('assets/Epreuves.json');
  final data = json.decode(response)[ravito]["CO"];
  final bool value = data as bool;
  return value;
}