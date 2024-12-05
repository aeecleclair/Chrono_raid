import 'package:chrono_raid/ui/popup_edit_temps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import 'database.dart';
import 'functions.dart';

class OngletEditTemps extends HookWidget {
  OngletEditTemps({super.key});

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();
    final refresh = useState(false);

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
          child: Column(
            children: [
              for (var parcours in ["Expert", "Sportif", "Découverte"]) ...[
                Text(
                  parcours,
                  style: const TextStyle(
                    fontSize: 30,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 20),
                if (temps[parcours] != null)
                  Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: epreuves[parcours].length + 2,
                          childAspectRatio: 50/(epreuves[parcours].length + 2),
                        ),
                        itemCount: epreuves[parcours].length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Center(
                              child: Text(
                                "Dossard",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          } else if (index <= epreuves[parcours].length) {
                            return Center(
                              child: Text(
                                epreuves[parcours][index - 1],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          } else {
                            return Container();
                          }
                        },
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: epreuves[parcours].length + 2,
                          childAspectRatio: 50/(epreuves[parcours].length + 2),
                        ),
                        itemCount: temps[parcours]!.entries.length *
                            (epreuves[parcours].length + 2),
                        itemBuilder: (context, index) {
                          int rowIndex = index ~/ (epreuves[parcours].length + 2);
                          int colIndex = (index % (epreuves[parcours].length + 2)).toInt();

                          final item = temps[parcours]!.entries.elementAt(rowIndex);

                          if (colIndex == 0) {
                            return Center(
                              child: FittedBox(
                                child: Text(
                                  item.key.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          } else if (colIndex <= epreuves[parcours].length) {
                            int epreuveIndex = colIndex - 1;
                            if (item.value.length > epreuveIndex) {
                              return Center(
                                child: Text(DateFormat('dd/MM - H:m:s')
                                    .format(DateTime.parse(item.value[epreuveIndex]))),
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
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
































// class OngletEditTemps extends HookWidget {
//   OngletEditTemps({super.key,});

//   @override
//   Widget build(BuildContext context) {
//     final dbm = DatabaseManager();
//     final refresh = useState(false);

//     return FutureBuilder<List<Object>>(
//       future: Future.wait([
//         dbm.getTempsOrderedbyDossard(),
//         readJsonEpreuves(),
//       ]),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Erreur: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(child: Text('Aucune donnée disponible'));
//         }
//         final data = snapshot.data as List;
//         final temps = data[0];
//         final epreuves = data[1];

//         return Center(
//           child: Column(
//             children: [
//               for (var parcours in ["Expert", "Sportif", "Découverte"]) ...[
//                 Text(
//                   parcours,
//                   style: TextStyle(
//                     fontSize: 30,
//                     decoration: TextDecoration.underline,
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Column(
//                   children: [
//                     if (temps[parcours] != null)
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             children: [
//                               const Row(children: [SizedBox(width: 50), Text("Dossard")],),
//                               SizedBox(height: 10),
//                               for (var item in temps[parcours]!.entries) ...[
//                                 Row(children: [SizedBox(width: 50), Text(item.key.toString())]),
//                                 SizedBox(height: 10),
//                               ],
//                             ],
//                           ),
//                           for (int i=0; i<epreuves[parcours].length; i++)
//                             Column(
//                               children: [
//                                 Text(epreuves[parcours][i]),
//                                 SizedBox(height: 10),
//                                 for (var item in temps[parcours]!.entries) ...[
//                                   Container(child: () {
//                                     if (item.value.length > i) {
//                                       return Text(DateFormat('dd/MM - H:m:s').format(DateTime.parse(item.value[i])));
//                                     } else {
//                                       return Text('-');
//                                     }
//                                   }()),
//                                   SizedBox(height: 10),
//                                 ],
//                               ],
//                             ),
//                           Column(
//                             children: [
//                               Text(""),
//                               for (var item in temps[parcours]!.entries) ...[
//                                 Row(
//                                   children: [
//                                     ElevatedButton(
//                                       child: const Text("Editer"),
//                                       onPressed: () {
//                                         showDialog(context: context, barrierDismissible: true, builder: (BuildContext context) {return PopupEditTemps(dossard: item.key.toString(), date: '', refresher: refresh);});
//                                       }
//                                     ),
//                                     SizedBox(width: 50),
//                                   ],
//                                 ),
//                                 SizedBox(height: 10),
//                               ],
//                             ],
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }
// }