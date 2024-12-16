import 'dart:math';

import 'package:chrono_raid/ui/functions.dart';
import 'package:flutter/foundation.dart';
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
  final scrollController = ScrollController();
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

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
                        return Text(dateToFormat(widget.date));
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
              Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: max(((epreuves.length) * 125).toDouble(), MediaQuery.of(context).size.width),
                    height: 250,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: epreuves.length,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3.5,
                      ),
                      itemCount: epreuves.length*4,
                      itemBuilder: (context, index) {
                        final rowIndex = index ~/ epreuves.length;
                        final colIndex = index % epreuves.length;
                        print(rowIndex);
                        if (rowIndex == 0) {
                          return Text(epreuves[index], textAlign: TextAlign.center,);
                        } else if (rowIndex == 1){
                          if (colIndex < temps.length) {
                            return Text(dateToFormat(temps[colIndex].date), textAlign: TextAlign.center,);
                          } else {
                            return Text('-', textAlign: TextAlign.center,);
                          }
                        } else if (rowIndex == 2) {
                          if (colIndex < temps.length) {
                            return ElevatedButton(
                              child: const Text("Remplacer"),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                if (widget.date.isNotEmpty) {
                                  await dbm.editTemps(temps[colIndex], widget.date);
                                } else {
                                  await dbm.editTemps(temps[colIndex], _selectedDate);
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
                                  alignment: isMobile ? Alignment.topLeft : Alignment.bottomRight,
                                );
                                widget.refresher.value = !widget.refresher.value;
                              },
                            );
                          } else if (colIndex == temps.length && widget.date.isEmpty) {
                            return ElevatedButton(
                              child: const Text("Ajouter"),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await dbm.createTemps(Temps(int.parse(widget.dossard), _selectedDate, parcours));
                                toastification.show(
                                  context: context,
                                  title: const Text('Temps ajouté !'),
                                  autoCloseDuration: const Duration(seconds: 3),
                                  primaryColor: Colors.black,
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.black,
                                  icon: const Icon(Icons.check_circle_outlined),
                                  closeOnClick: true,
                                  alignment: isMobile ? Alignment.topLeft : Alignment.bottomRight,
                                );
                                widget.refresher.value = !widget.refresher.value;
                              },
                            );
                          } else {
                            return Container();
                          }
                        } else if (rowIndex == 3) {
                          if (widget.date.isEmpty && colIndex < temps.length) {
                            return ElevatedButton(
                              child: const Text("Supprimer"),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await dbm.deleteTemps(temps[colIndex]);
                                toastification.show(
                                  context: context,
                                  title: const Text('Temps supprimé !'),
                                  autoCloseDuration: const Duration(seconds: 3),
                                  primaryColor: Colors.black,
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.black,
                                  icon: const Icon(Icons.check_circle_outlined),
                                  closeOnClick: true,
                                  alignment: isMobile ? Alignment.topLeft : Alignment.bottomRight,
                                );
                                widget.refresher.value = !widget.refresher.value;
                              },
                            );
                          } else {
                            return Container();
                          }
                        } else {
                          return Container();
                        }
                      }
                    )
                  ),
                ),
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