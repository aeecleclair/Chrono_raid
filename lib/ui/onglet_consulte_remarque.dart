import 'package:chrono_raid/ui/database.dart';
import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/ui/remarque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class OngletConsulteRemarque extends HookWidget {
  final String ravito;
  const OngletConsulteRemarque(
    this.ravito, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();

    return FutureBuilder<List<Remarque>>(
      future: dbm.getRemarque(ravito),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune remarque disponible'));
        }

        final data = snapshot.data!
            .map((r) => {
                  'date': dateToFormat(r.date),
                  'ravito': r.ravito,
                  'text': r.text
                })
            .toList();
        data.insert(
            0, {'date': 'Date', 'ravito': 'Ravito', 'text': 'Remarque'});

        return GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: MediaQuery.of(context).size.width / 3 / 40,
            mainAxisSpacing: 10,
          ),
          itemCount: data.length * 3,
          itemBuilder: (context, index) {
            final rowIndex = index ~/ 3;
            final columnIndex = index % 3;

            final r = data[rowIndex];

            final String t = r['text'] ?? '';

            switch (columnIndex) {
              case 0:
                return Text(
                  r['date']!,
                  textAlign: TextAlign.center,
                );
              case 1:
                return Text(
                  r['ravito']!,
                  textAlign: TextAlign.center,
                );
              case 2:
                return t.length < 10
                    ? Text(t, textAlign: TextAlign.center)
                    : TextButton(
                        child: Text(
                            '${t.substring(0, 10).replaceAll(RegExp(r'[\n\r]'), ' ')} ...',
                            textAlign: TextAlign.center),
                        onPressed: () => showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              scrollable: true,
                              title: Text('Remarque'),
                              content: Text(t),
                            );
                          },
                        ),
                      );
              default:
                return Container();
            }
          },
        );
      },
    );
  }
}
