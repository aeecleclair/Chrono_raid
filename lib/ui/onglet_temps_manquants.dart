import 'package:chrono_raid/ui/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletTempsManquants extends HookWidget {
  const OngletTempsManquants({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();
    final refresh = useState(false);
    final dropdown = useState<Map<String, bool>?>(null);

    return FutureBuilder<List<String>>(
        future: getParcours(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun parcours disponible'));
          }

          final list_parcours = snapshot.data!;
          if (dropdown.value == null && list_parcours.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              dropdown.value = {
                for (var parcours in list_parcours) parcours: true
              };
            });
          }

          return FutureBuilder(
            future: dbm.compteTempsManquants(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Aucun temps manquant'));
              }

              final data = snapshot.data;

              return Center(
                  child: Column(children: [
                for (var parcours in list_parcours) ...[
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
                          dropdown.value![parcours] =
                              !dropdown.value![parcours]!;
                          refresh.value = !refresh.value;
                        },
                        child: dropdown.value![parcours]!
                            ? Icon(Icons.keyboard_arrow_up)
                            : Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (data![parcours] != null &&
                      data[parcours]!.isNotEmpty &&
                      dropdown.value![parcours]!)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio:
                            MediaQuery.of(context).size.width / 3 / 40,
                      ),
                      itemCount: (data[parcours]!.length + 1) * 3,
                      itemBuilder: (context, index) {
                        final rowIndex = (index ~/ 3);
                        final colIndex = index % 3;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.black, width: 0.5)),
                          ),
                          child: () {
                            if (rowIndex == 0) {
                              return Center(
                                child: Text(
                                  ['Dossard', 'Ravito', 'Nombre'][index],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            } else {
                              final d = data[parcours]![rowIndex - 1];
                              return Center(
                                child: Text(
                                  [
                                    d['dossard']!,
                                    d['ravito']!,
                                    d['nb']!
                                  ][colIndex],
                                ),
                              );
                            }
                          }(),
                        );
                      },
                    ),
                ]
              ]));
            },
          );
        });
  }
}
