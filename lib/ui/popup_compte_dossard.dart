import 'package:flutter/material.dart';
import 'database.dart';

class PopupCompteDossard extends StatelessWidget {
  final String epreuve;
  final String parcours;

  const PopupCompteDossard({super.key, required this.epreuve, required this.parcours});

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();
    return FutureBuilder<List<int>>(
      future: dbm.compteDossard(parcours, epreuve),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final data = snapshot.data!;

        return AlertDialog(
          scrollable: true,
          title: Text('Equipes : $epreuve'),
          content: 
            Container(child: () {
              if (data.isEmpty) {
                return Text('Aucune équipe à cet endroit');
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var dos in data)
                    Text(dos.toString()),
                  ]
                );
              }
            }()),
          
          actions: [
            ElevatedButton(
              child: const Text("Fermer"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }
}