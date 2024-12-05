import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/ui/remarque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletRemarque extends HookWidget {
  OngletRemarque({super.key,});
  final TextEditingController _controllerRemarque = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final test = useState('');
    final dbm = DatabaseManager();

    void button_test() async {
      await dbm.createTableEquipes();
      await dbm.test();
      print("table equipes créée");
      // String txt = '';
      // final List<Temps> liste = (await dbm.getTemps()).toList();
      // for (int i=0; i < liste.length; i++) {
      //   txt += liste[i].dossard.toString() + ' ' + liste[i].parcours.toString() + ' ' + liste[i].date.toString() + '\n';
      // }
      // test.value = txt;
      //final a = (await dbm.getParcoursByDossard(1));
      //print(a);
      final tamere = await dbm.getAction();
      print(tamere.map((e) => e.toString() + '\n').toList());
      // print(tamere);
      // test.value = tamere.toString();

    }

    void envoyer() async {
      final dbm = DatabaseManager();
      String remarque_text = _controllerRemarque.text;
      await dbm.createRemarque(Remarque(DateTime.now().toIso8601String(), remarque_text));

    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            width: 600,
            height: 300,
            child: TextField(
              controller: _controllerRemarque,
              maxLines: 20,
              minLines: 10,
              style: TextStyle(
                color: Colors.black,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: envoyer,
            child: const Text('Envoyer'),
          ),
          FloatingActionButton(
            onPressed: button_test,
            child: const Text('Test'),
          ),
          Text(
            test.value,
          ),
        ],
      ),
    );
  }
}