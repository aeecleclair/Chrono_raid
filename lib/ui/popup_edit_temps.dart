import 'dart:math';

import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/tools/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database.dart';
import 'temps.dart';

class PopupEditTemps extends StatefulWidget {
  final String dossard;
  final String date;
  final String ravito;
  final refresher;

  const PopupEditTemps({
    super.key,
    required this.dossard,
    required this.date,
    required this.ravito,
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

    return FutureBuilder<List<Object>>(
        future: Future.wait([
          dbm.getParcoursByDossard(widget.dossard),
          dbm.getTempsbyDossard(widget.dossard, widget.ravito),
          readJsonEpreuves(widget.ravito),
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
          final int nb_cols = min(temps.length + 1, epreuves.length);

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
                                child: Text(DateFormat('dd/MM - HH:mm:ss')
                                    .format(DateTime.parse(_selectedDate))),
                              );
                            }
                          }()),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                          width: (nb_cols * (kIsMobile ? 150 : 200)).toDouble(),
                          height: 250,
                          child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: nb_cols,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 3.5,
                              ),
                              itemCount: nb_cols * 4,
                              itemBuilder: (context, index) {
                                final rowIndex = index ~/ nb_cols;
                                final colIndex = index % nb_cols;

                                if (rowIndex == 0) {
                                  return Text(
                                    epreuves[index],
                                    textAlign: TextAlign.center,
                                  );
                                } else if (rowIndex == 1) {
                                  if (colIndex < nb_cols - 1 ||
                                      (colIndex == nb_cols - 1 &&
                                          nb_cols == epreuves.length &&
                                          temps.length > colIndex)) {
                                    return Text(
                                      dateToFormat(temps[colIndex].date),
                                      textAlign: TextAlign.center,
                                    );
                                  } else {
                                    return Text(
                                      '-',
                                      textAlign: TextAlign.center,
                                    );
                                  }
                                } else if (rowIndex == 2) {
                                  if (colIndex < nb_cols - 1 ||
                                      (colIndex == nb_cols - 1 &&
                                          nb_cols == epreuves.length &&
                                          temps.length > colIndex)) {
                                    return ElevatedButton(
                                      child: const Text("Remplacer"),
                                      onPressed: () async {
                                        if (widget.date.isNotEmpty) {
                                          await dbm.editTemps(
                                              temps[colIndex], widget.date);
                                        } else {
                                          await dbm.editTemps(
                                              temps[colIndex], _selectedDate);
                                        }
                                        notif(
                                            context,
                                            'Temps modifié !',
                                            Colors.green,
                                            Icons.check_circle_outline);
                                        widget.refresher.value =
                                            !widget.refresher.value;
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  } else if (widget.date.isEmpty &&
                                      colIndex == nb_cols - 1) {
                                    return ElevatedButton(
                                      child: const Text("Ajouter"),
                                      onPressed: () async {
                                        try {
                                          await dbm.createTemps(Temps(
                                              int.parse(widget.dossard),
                                              _selectedDate,
                                              parcours,
                                              widget.ravito,
                                              true,
                                              DateTime.now()
                                                  .toIso8601String()));
                                          notif(
                                              context,
                                              'Temps ajouté !',
                                              Colors.green,
                                              Icons.check_circle_outline);
                                          widget.refresher.value =
                                              !widget.refresher.value;
                                          Navigator.of(context).pop();
                                        } catch (e) {
                                          notif(
                                              context,
                                              e.toString(),
                                              Colors.red,
                                              Icons.cancel_outlined);
                                        }
                                      },
                                    );
                                  } else {
                                    return Container();
                                  }
                                } else if (rowIndex == 3) {
                                  if (widget.date.isEmpty &&
                                      (colIndex < nb_cols - 1 ||
                                          (colIndex == nb_cols - 1 &&
                                              nb_cols == epreuves.length &&
                                              temps.length > colIndex))) {
                                    return ElevatedButton(
                                      child: const Text("Supprimer"),
                                      onPressed: () async {
                                        await dbm.deleteTemps(temps[colIndex]);
                                        notif(
                                            context,
                                            'Temps supprimé !',
                                            Colors.green,
                                            Icons.check_circle_outline);
                                        widget.refresher.value =
                                            !widget.refresher.value;
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  } else {
                                    return Container();
                                  }
                                } else {
                                  return Container();
                                }
                              })),
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
                    widget.refresher.value = !widget.refresher.value;
                    Navigator.of(context).pop();
                  },
                ),
              ]);
        });
  }
}
