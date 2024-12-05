import 'package:chrono_raid/ui/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletEditAction extends HookWidget {
  OngletEditAction({super.key,});

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();
    final refresh = useState(false);

    return FutureBuilder<List<Object>>(
      future: dbm.getAction(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final data = snapshot.data as List;

        return Center(
          child: Column(
            children: [
              const SizedBox(height: 30,),
              ElevatedButton(
                child: const Column(
                  children: [
                    SizedBox(height: 10,),
                    Text(
                      "Annuler la dernière action",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10,),
                  ],
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        scrollable: true,
                        title: Text('Confirmation'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Fermer')
                          ),
                          ElevatedButton(
                            child: const Text("Confirmer"),
                            onPressed: () {
                              dbm.annuleDerniereAction();
                              Navigator.of(context).pop();
                              refresh.value = !refresh.value;
                            },
                          ),
                        ]
                      );
                    }
                  );
                }
              ),
              const SizedBox(height: 20,),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 8,
                  ),
                  itemCount: data.isNotEmpty? 6 + (data.length * 6) : 6,
                  itemBuilder: (context, index) {
                    if (index < 6) {
                      return Center(
                        child: Text(
                          ['Date', 'Type', 'Parcours', 'Dossard', 'Ancien temps', 'Nouveau temps'][index],
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else {
                      final rowIndex = (index - 6) ~/ 6;
                      final colIndex = (index - 6) % 6;

                      final action = data[rowIndex];
                
                      final cellData = [
                        dateToFormat(action.date),
                        action.type,
                        action.parcours,
                        action.dossard,
                        dateToFormat(action.ancien_temps),
                        dateToFormat(action.nouveau_temps)
                      ][colIndex];
                
                      return Center(
                        child: Text(
                          cellData,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),               
        );
      },    
    );
  }
}
