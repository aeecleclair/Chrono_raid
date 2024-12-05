import 'dart:convert';

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

Future<Map<String, List<String>>> readJsonEpreuves() async {
  final String response = await rootBundle.loadString('assets/Epreuves.json');
  final Map<String, dynamic> data = json.decode(response)["Epreuves"];
  final Map<String, List<String>> data2 = data.map(
    (key, value) => MapEntry(
      key,
      List<String>.from(value),
    ),
  );
  return data2;
}

String dateToFormat(String date) {
  if (date == '-') {
    return '-';
  }
  else {
    return DateFormat('dd/MM - H:m:s').format(DateTime.parse(date));
  }
}