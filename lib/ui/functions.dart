import 'dart:convert';

import 'package:flutter/services.dart';

Future<List<Map<String,String>>> readJsonEquipes() async {
  final String response = await rootBundle.loadString('assets/Equipes.json');
  final data = await json.decode(response)["Equipes"];
  final List<Map<String,String>> data2 = [];
  for (int i=0; i<data.length; i++) {
    data2.add({"dossard":data[i]["dossard"],"parcours":data[i]["parcours"]});
  }
  return data2;
}

Future<Map<String, List<String>>> readJsonEpreuves() async {
  final String response = await rootBundle.loadString('assets/Epreuves.json');
  final Map<String, dynamic> data = json.decode(response);
  final Map<String, List<String>> data2 = (data["Epreuves"] as Map<String, dynamic>).map(
    (key, value) => MapEntry(
      key,
      List<String>.from(value),
    ),
  );
  return data2;
}