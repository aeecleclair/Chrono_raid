import 'package:chrono_raid/ui/popup_compte_dossard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletCompte extends HookWidget {
  final String ravito;
  OngletCompte(this.ravito, {super.key,});

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();

    return FutureBuilder<Map<String,Map<String,int>>>(
      future: dbm.compteTemps(ravito),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucune donnée disponible'));
        }

        final data = snapshot.data!;
        
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var parcours in ["Expert", "Sportif", "Découverte"])
                Column(
                  children: <Widget>[
                  Text(parcours,
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
                          return PopupCompteDossard(epreuve: item.key, parcours: parcours, ravito: ravito,);
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