import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:chrono_raid/tools/repository/csv_repository.dart';
import 'package:chrono_raid/tools/repository/json_repository.dart';
import 'package:chrono_raid/tools/repository/temps_repository.dart';
import 'package:chrono_raid/ui/database.dart';
import 'package:chrono_raid/ui/json_folder_storage.dart';
import 'package:chrono_raid/ui/remarque.dart';
import 'package:chrono_raid/ui/temps.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chrono_raid/tools/constants.dart';
import 'package:toastification/toastification.dart';

Future<List<Map<String, String>>> readJsonEquipes() async {
  final String response = await loadJsonEquipes();
  final List<dynamic> data = await json.decode(response)["Equipes"];
  final List<Map<String, String>> data2 = data
      .map((item) => {
            "dossard": item["dossard"] as String,
            "parcours": item["parcours"] as String,
          })
      .toList();
  return data2;
}

Future<List<String>> getParcours({String? ravito}) async {
  final String response = await loadJsonEpreuves();
  Map<String, dynamic> data = jsonDecode(response);
  if (ravito != null) {
    return data[ravito]?['Epreuves']?.keys.toList() ?? [];
  }
  return data.values
      .expand((entry) => (entry['Epreuves'] as Map<String, dynamic>).keys)
      .toSet()
      .toList();
}

Future<Map<String, List<String>>> readJsonEpreuves(ravito) async {
  final String response = await loadJsonEpreuves();
  final d = json.decode(response);
  final Map<String, dynamic> data;
  if (ravito == 'admin') {
    final List<String> list_parcours = await getParcours();
    data = {for (var parcours in list_parcours) parcours: []};
    for (var r in d.keys) {
      for (var p in list_parcours) {
        data[p] = [data[p], d[r]["Epreuves"][p]].expand((x) => x).toList();
      }
    }
  } else {
    data = d[ravito]["Epreuves"];
  }
  final Map<String, List<String>> data2 = Map.fromEntries(
    data.entries.map(
      (entry) => MapEntry(
        entry.key,
        List<String>.from(entry.value),
      ),
    ),
  );
  return data2;
}

Future compteEpreuves() async {
  final String response = await loadJsonEpreuves();
  final d = json.decode(response);
  final List<String> list_parcours = await getParcours();
  final Map<String, dynamic> data = {
    for (var parcours in list_parcours) parcours: {}
  };
  for (var r in d.keys) {
    for (var p in list_parcours) {
      data[p][r] = d[r]["Epreuves"][p].length;
    }
  }
  return data;
}

Future<List<String>> getRavitos() async {
  final String response = await loadJsonEpreuves();
  final Map<String, dynamic> data = json.decode(response);
  return List<String>.from(data.keys);
}

String dateToFormat(String date) {
  if (date == '-') {
    return '-';
  } else {
    return kIsMobile
        ? DateFormat('dd/MM\nH:m:s').format(DateTime.parse(date))
        : DateFormat('dd/MM - H:m:s').format(DateTime.parse(date));
  }
}

enum ActionType {
  Default,
  DepartSimple,
  DepartGroupe,
  Delete,
  Edit,
}

final Map<ActionType, String> actionTypeToStringMap = {
  for (var at in ActionType.values) at: at.toString().split('.').last
};

final Map<String, ActionType> stringToActionTypeMap = {
  for (var at in ActionType.values) at.toString().split('.').last: at
};

String actionTypeToString(ActionType at) {
  return actionTypeToStringMap[at] ?? 'Default';
}

ActionType stringToActionType(String at) {
  return stringToActionTypeMap[at] ?? ActionType.Default;
}

Future<bool> jsonHasChanged() async {
  final JsonRepository jsonRepository = JsonRepository();

  final data_epreuves = await jsonRepository.getJson("Epreuves");
  final data_equipes = await jsonRepository.getJson("Equipes");

  bool epreuvesHasChanged = await jsonIsChanged("Epreuves", data_epreuves);
  bool equipesHasChanged = await jsonIsChanged("Equipes", data_equipes);

  return epreuvesHasChanged || equipesHasChanged;
}

Future<void> jsonUpdate() async {
  final JsonRepository jsonRepository = JsonRepository();

  final data_epreuves = await jsonRepository.getJson("Epreuves");
  final data_equipes = await jsonRepository.getJson("Equipes");

  await replaceJson("Epreuves", data_epreuves);
  await replaceJson("Equipes", data_equipes);
}

Future<void> synchronisation(String last_syncro_date) async {
  final ClassicRepository repository = ClassicRepository();
  final dbm = DatabaseManager();

  // Temps

  List<Temps> list_temps = await dbm.getTempsSince(last_syncro_date);

  List<dynamic> list_new_temps = (await repository.create(
          list_temps.map((t) => t.toJson()).toList(),
          suffix: 'chrono_raid/temps/$last_syncro_date'))
      .map((t) => Temps.fromJson(t))
      .toList();

  for (var t in list_new_temps) {
    final existing_t = await dbm.getTempsbyId(t.id);
    if (existing_t != null) {
      await dbm.updateTemps(t);
    } else {
      await dbm.addTemps(t);
    }
  }

  // await dbm.deleteTempsSince(last_syncro_date);
  // await dbm.addListTemps(list_new_temps);

  // Remarques

  List<Remarque> list_remarques_local = await dbm.getRemarque('admin');

  List<Remarque> list_remarques_serv =
      (await repository.getList(suffix: 'chrono_raid/remarks'))
          .map((r) => Remarque.fromJson(r))
          .toList();

  final ids_serv = list_remarques_serv.map((e) => e.id).toSet();
  final ids_local = list_remarques_local.map((e) => e.id).toSet();

  List<Remarque> list_serv_minus_local =
      list_remarques_serv.where((obj) => !ids_local.contains(obj.id)).toList();
  List<Remarque> list_local_minus_serv =
      list_remarques_local.where((obj) => !ids_serv.contains(obj.id)).toList();

  for (var r in list_serv_minus_local) {
    dbm.createRemarque(r);
  }
  if (list_local_minus_serv.isNotEmpty) {
    await repository.create(
        list_local_minus_serv.map((r) => r.toJson()).toList(),
        suffix: "chrono_raid/remarks");
  }
}

void download_csv() async {
  CsvRepository csvRepository = CsvRepository();

  for (var parcours in await getParcours()) {
    csvRepository
        .getCsv(suffix: 'chrono_raid/csv_temps/$parcours')
        .then((csvData) async {
      final directory;

      if (kIsDesktop) {
        directory = await getDownloadsDirectory();
      } else {
        await requestPermissions();
        directory = await getExternalStorageDirectory();
      }

      final path = '${directory?.path}/Temps_$parcours.csv';

      final file = File(path);
      await file.writeAsString(csvData);
    }).catchError((error) {
      print('Error: $error');
    });
  }
}

Future<void> requestPermissions() async {
  if (Platform.isAndroid) {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Permission refusée');
    }
  } else if (Platform.isIOS) {
    var status = await Permission.photos.request();
    if (!status.isGranted) {
      throw Exception('Permission refusée');
    }
  }
}

void notif(BuildContext context, String text, Color color, IconData icon) {
  toastification.show(
    context: context,
    title: Text(text),
    autoCloseDuration: const Duration(seconds: 3),
    primaryColor: Colors.black,
    backgroundColor: color,
    foregroundColor: Colors.black,
    icon: Icon(icon),
    closeOnClick: true,
    alignment: kIsMobile ? Alignment.topLeft : Alignment.bottomRight,
  );
}
