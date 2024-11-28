import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletTest extends HookWidget {
  OngletTest({super.key,});

  @override
  Widget build(BuildContext context) {
    final test = useState('');
    final dbm = DatabaseManager();

    void envoyer() async {
      await dbm.createTableEquipes();
      // String txt = '';
      // final List<Temps> liste = (await dbm.getTemps()).toList();
      // for (int i=0; i < liste.length; i++) {
      //   txt += liste[i].dossard.toString() + ' ' + liste[i].parcours.toString() + ' ' + liste[i].date.toString() + '\n';
      // }
      // test.value = txt;
      //final a = (await dbm.getParcoursByDossard(1));
      //print(a);
      final tamere = await dbm.getTempsOrderedbyDossard();
      // print(tamere.map((e) => e.toString() + '\n').toList());
      print(tamere);
      // test.value = tamere.toString();

    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
            FloatingActionButton(
            onPressed: envoyer,
            child: const Text('Afficher'),
          ),
          Text(
            test.value,
          ),
        ],
      ),
    );
  }
}