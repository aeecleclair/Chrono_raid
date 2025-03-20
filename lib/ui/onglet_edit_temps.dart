import 'dart:math';

import 'package:chrono_raid/ui/popup_edit_temps.dart';
import 'package:chrono_raid/tools/constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';
import 'functions.dart';

class OngletEditTemps extends HookWidget {
  final String ravito;
  final pageScrollController;
  const OngletEditTemps(this.ravito, this.pageScrollController, {super.key});

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
            dropdown.value = {for (var parcours in list_parcours) parcours: true};
          });
        }
 
        final Map<String, ScrollController> scrollController = {for (var parcours in list_parcours) parcours: ScrollController()};
        final ScrollController verticalScrollController = ScrollController();
        
        return FutureBuilder<List<Object>>(
          future: Future.wait([
            dbm.getTempsOrderedbyDossard(ravito),
            readJsonEpreuves(ravito),
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
            final temps = data[0] as Map<String, dynamic>;
            final epreuves = data[1] as Map<String, dynamic>;
            
            return SingleChildScrollView(
              controller: verticalScrollController,
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
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
                            dropdown.value![parcours] = !dropdown.value![parcours]!;
                            refresh.value = !refresh.value;
                          },
                          child: dropdown.value![parcours]! ? const Icon(Icons.keyboard_arrow_up) : const Icon(Icons.keyboard_arrow_down),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (temps[parcours] != null && dropdown.value![parcours]!)
                      // GestureDetector(
                      //   onVerticalDragUpdate: (details) {
                      //     verticalScrollController.jumpTo(
                      //       verticalScrollController.offset - details.primaryDelta!,
                      //     );
                      //     print(details.primaryDelta);
                      //   },
                      //   onHorizontalDragUpdate: (details) {
                      //     print(details.primaryDelta);
                      //   },
                      //   onTap: () {
                      //     print('aah');
                      //   },
                      Listener(
                        onPointerSignal: (PointerSignalEvent event) {
                          if (event is PointerScrollEvent) {
                            //print('aaa ${event.scrollDelta.dy}');
                          }
                        },
                        onPointerMove: (PointerMoveEvent event) {
                          if (event.kind == PointerDeviceKind.trackpad) {
                            //print(-event.delta.dy);
                          }
                        },
                      child: Scrollbar(
                        controller: scrollController[parcours],
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: scrollController[parcours],
                          scrollDirection: Axis.horizontal,
                          child: Builder(
                            builder: (context) {
                              double w = max(((epreuves[parcours].length + 2) * (kIsMobile ? 80 : 120)).toDouble(), MediaQuery.of(context).size.width);
                              return SizedBox(
                                width: w,
                                child: grid(epreuves[parcours], temps[parcours], kIsMobile, refresh, w),
                              );
                            },
                          ),
                        ),
                      ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget grid(epreuves, temps, kIsMobile, refresh, w) {
    return  GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: epreuves.length + 2,
        childAspectRatio: w/(epreuves.length + 2)/50,
      ),
      itemCount: epreuves.length + 2 + temps.length * (epreuves.length + 2),
      itemBuilder: (context, index) {
        int rowIndex = index ~/ (epreuves.length + 2);
        int colIndex = (index % (epreuves.length + 2)).toInt();
    
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 0.5)),
          ),
          child: () {
            if (rowIndex == 0) {
              if (index == 0) {
                return Center(
                  child: Text(
                    "Dossard",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                );
              } else if (index <= epreuves.length) {
                return Center(
                  child: Text(
                    kIsMobile? epreuves[index - 1].replaceFirst(' ', '\n') : epreuves[index - 1],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                return Container();
              }
            }
        
            final item = temps!.entries.elementAt(rowIndex-1);
        
            if (colIndex == 0) {
              return Center(
                child: Text(
                  item.key.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            } else if (colIndex <= epreuves.length) {
              int epreuveIndex = colIndex - 1;
              if (item.value.length > epreuveIndex) {
                return Center(
                  child: Text(dateToFormat(item.value[epreuveIndex]), textAlign: TextAlign.center,),
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
                            ravito: ravito,
                            refresher: refresh,
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            }
          }()
        );
      },
    );
  }
}
