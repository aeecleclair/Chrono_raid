import 'package:chrono_raid/ui/functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'database.dart';
import 'temps.dart';

class PopupEditTemps extends StatefulWidget {
  final String dossard;
  final String date;
  final refresher;

  const PopupEditTemps({
    super.key,
    required this.dossard,
    required this.date,
    this.refresher,
  });

  @override
  _PopupEditTempsState createState() => _PopupEditTempsState();
}

class _PopupEditTempsState extends State<PopupEditTemps> {
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();

    return FutureBuilder<List<Object>>(
      future: Future.wait([
        dbm.getParcoursByDossard(widget.dossard),
        dbm.getTempsbyDossard(widget.dossard),
        readJsonEpreuves(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final data = snapshot.data as List;
        final String parcours = data[0];
        final List<Temps> temps = data[1];
        final List<String> epreuves = data[2][parcours];
      

        return AlertDialog(
          scrollable: true,
          title: Container(child: () {
                if (widget.date.isNotEmpty) {
                  return Text(["Résoudre : dossard ", widget.dossard].join(''));
                } else {
                  return Text(["Editer : dossard ", widget.dossard].join(''));
                }
              }()),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      if (widget.date.isNotEmpty) {
                        return Text(DateFormat('dd/MM - H:m:s').format(DateTime.parse(widget.date)));
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
                                    setState(() {
                                      _selectedDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        selectedTime.hour,
                                        selectedTime.minute,
                                        0,
                                      ).toIso8601String();
                                    });

                                  }
                                });
                              }
                            });
                          },
                          child: Text(DateFormat('dd/MM - HH:mm:ss').format(DateTime.parse(_selectedDate))),
                        );
                                }
                  }()),
                  

                ],
              ),
              SizedBox(height: 40,),
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
                          Container(child: () {
                            if (i < temps.length) {
                              return Text(dateToFormat(temps[i].date));
                            } else {
                              return Text('-');
                            }
                          }()),
                          Container(child: () {
                            if (i < temps.length) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    child: const Text("Remplacer"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.refresher.value = !widget.refresher.value;
                                      if (widget.date.isNotEmpty) {
                                        dbm.editTemps(temps[i], widget.date);
                                      } else {
                                        dbm.editTemps(temps[i], _selectedDate);
                                      }
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
                                  if (widget.date.isEmpty)
                                    SizedBox(height: 20,),
                                    ElevatedButton(
                                      child: const Text("Supprimer"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        widget.refresher.value = !widget.refresher.value;
                                        dbm.deleteTemps(temps[i]);
                                        toastification.show(
                                          context: context,
                                          title: const Text('Temps supprimé !'),
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
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: null,
                                    child: const Text("Remplacer"),
                                  ),
                                  if (widget.date.isEmpty)
                                    SizedBox(height: 20,),
                                    ElevatedButton(
                                      onPressed: null,
                                      child: const Text("Supprimer"),
                                    ),
                                ],
                              );
                            }
                          }()),

                        ]
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          actions: [
            ElevatedButton(
              child: Container(child: () {
                if (widget.date.isNotEmpty) {
                  return const Text("Ignorer le nouveau temps");
                } else {
                  return Text('Annuler');
                }
              }()),
              onPressed: () {
                Navigator.of(context).pop();
                widget.refresher.value = !widget.refresher.value;
              },
            ),
          ]
        );
      }
    );
  }
}