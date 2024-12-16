import 'dart:math';

import 'package:chrono_raid/ui/popup_edit_temps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';
import 'functions.dart';

class OngletEditTemps extends HookWidget {
  OngletEditTemps({super.key});

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();
    final refresh = useState(false);
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    final dropdown = useState({"Expert":true, "Sportif":false, "Découverte":false});

    return FutureBuilder<List<Object>>(
      future: Future.wait([
        dbm.getTempsOrderedbyDossard(),
        readJsonEpreuves(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune donnée disponible'));
        }
        final data = snapshot.data as List;
        final temps = data[0];
        final epreuves = data[1];

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              for (var parcours in ["Expert", "Sportif", "Découverte"]) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      parcours,
                      style: const TextStyle(
                        fontSize: 30,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        dropdown.value[parcours] = !dropdown.value[parcours]!;
                        refresh.value = !refresh.value;
                      },
                      child: dropdown.value[parcours]! ? Icon(Icons.keyboard_arrow_up) : Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (temps[parcours] != null && dropdown.value[parcours]!)
                  if (isMobile) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                        ),
                        child: SizedBox(
                          width: max(((epreuves[parcours].length + 2) * 80).toDouble(), MediaQuery.of(context).size.width),
                          child: grid(epreuves[parcours], temps[parcours], isMobile, refresh),
                        ),
                        
                      ),
                    ),
                  ] else ...[
                    grid(epreuves[parcours], temps[parcours], isMobile, refresh),
                  ],
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget grid(epreuves, temps, isMobile, refresh) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: epreuves.length + 2,
        childAspectRatio: isMobile ? 1.5 : 50/(epreuves.length + 2),
      ),
      itemCount: epreuves.length + 2 + temps.length * (epreuves.length + 2),
      itemBuilder: (context, index) {
        int rowIndex = index ~/ (epreuves.length + 2);
        int colIndex = (index % (epreuves.length + 2)).toInt();
    
        if (rowIndex == 0) {
          if (index == 0) {
            return Center(
              child: Text(
                "Dossard",
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            );
          } else if (index <= epreuves.length) {
            return Center(
              child: Text(
                isMobile? epreuves[index - 1].replaceFirst(' ', '\n') : epreuves[index - 1],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          } else {
            return Container();
          }
        }
    
        final item = temps!.entries.elementAt(rowIndex-1);
    
        if (colIndex == 0) {
          return Center(
            child: Text(
              item.key.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        } else if (colIndex <= epreuves.length) {
          int epreuveIndex = colIndex - 1;
          if (item.value.length > epreuveIndex) {
            return Center(
              child: Text(dateToFormat(item.value[epreuveIndex]), textAlign: TextAlign.center,),
            );
          } else {
            return const Center(child: Text('-'));
          }
        } else {
          return Center(
            child: SizedBox(
              width: 100,
              height: 30,
              child: ElevatedButton(
                child: const Text("Editer"),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return PopupEditTemps(
                        dossard: item.key.toString(),
                        date: '',
                        refresher: refresh,
                      );
                    },
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}
