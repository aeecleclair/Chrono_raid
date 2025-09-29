import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/ui/popup_compte_dossard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletCompte extends HookWidget {
  final String ravito;
  const OngletCompte(
    this.ravito, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([getParcours(ravito: ravito), dbm.compteTemps(ravito)]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData ||
            snapshot.data![0].isEmpty ||
            snapshot.data![1].isEmpty) {
          return const Center(child: Text('Aucune donnée disponible'));
        }

        final list_parcours = snapshot.data![0] as List<String>;
        final data = snapshot.data![1] as Map<String, Map<String, int>>;

        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var parcours in list_parcours)
                Column(
                  children: <Widget>[
                    Text(
                      parcours,
                      style: TextStyle(
                        fontSize: 30,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    for (var item in data[parcours]!.entries)
                      TextButton(
                        onPressed: () => showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext context) {
                            return PopupCompteDossard(
                              epreuve: item.key,
                              parcours: parcours,
                              ravito: ravito,
                            );
                          },
                        ),
                        child: Text("${item.key} : ${item.value}"),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
