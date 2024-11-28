import 'package:chrono_raid/ui/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'database.dart';
import 'temps.dart';

class PopupEditTemps extends StatelessWidget {
  final String dossard;
  final String date;

  PopupEditTemps({super.key, required this.dossard, required this.date});

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();

    return FutureBuilder<List<Object>>(
      future: Future.wait([
        dbm.getParcoursByDossard(dossard),
        dbm.getTempsbyDossard(dossard),
        readJsonEpreuves(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final data = snapshot.data as List;
        print(data);
        final String parcours = data[0];
        final List<Temps> temps = data[1];
        final List<String> epreuves = data[2][parcours];
      

        return AlertDialog(
          scrollable: true,
          title: Text(["Résoudre : dossard ", dossard].join('')),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < epreuves.length; i++)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Wrap(
                        direction: Axis.vertical, 
                        spacing: 20,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(epreuves[i]),
                          Text(DateFormat('dd/MM - H:m:s').format(DateTime.parse(temps[i].date))),
                          ElevatedButton(
                            child: const Text("Remplacer"),
                            onPressed: () {
                              Navigator.of(context).pop();
                              dbm.editTemps(temps[i], date);
                              toastification.show(
                                context: context,
                                title: const Text('Temps modifié !'),
                                autoCloseDuration: const Duration(seconds: 3),
                                primaryColor: Colors.black,
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.black,
                                icon: const Icon(Icons.check_circle_outlined),
                                closeOnClick: true,
                                alignment: Alignment.bottomRight,
                              );
                            },
                          ),
                        ]
                      ),
                    ),
                ],
              ),
              SizedBox(height: 40,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Nouveau Temps : '),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: () {
                      if (date.isNotEmpty) {
                        return Text(DateFormat('dd/MM - H:m:s').format(DateTime.parse(date)));
                      } else {
                        return TextButton(
                          onPressed: () {
                            showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            ).then((selectedDate) {
                              if (selectedDate != null) {
                                showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                ).then((selectedTime) {
                                  if (selectedTime != null) {
                                    DateTime selectedDateTime = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                    print(selectedDateTime);
                                  }
                                });
                              }
                            });
                          },
                          child: Text('Choisir')
                        );
                                }
                  }()),
                  

                ],
              )
            ],
          ),
          
          actions: [
            ElevatedButton(
              child: const Text("Ignorer le nouveau temps"),
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
