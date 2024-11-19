import 'package:chrono_raid/ui/database.dart';
import 'package:chrono_raid/ui/temps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:toastification/toastification.dart';

class OngletDossardUnique extends HookWidget {
  OngletDossardUnique({super.key,});

  final TextEditingController _controllerDossard = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dossard = useState('');
    final dbm = DatabaseManager();
    
    void envoyer() async {
      String dossard_str = _controllerDossard.text;
      dossard.value = dossard_str;
      if (dossard_str != '' && await dbm.valideDossard(dossard_str)) {
        _controllerDossard.clear();
        dbm.createTemps(Temps(int.parse(dossard_str), DateTime.now().toIso8601String(), await dbm.getParcoursByDossard(dossard_str)));
        toastification.show(
          context: context,
          title: const Text('Temps ajouté !'),
          autoCloseDuration: const Duration(seconds: 3),
          primaryColor: Colors.black,
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.check_circle_outlined),
          closeOnClick: true,
          alignment: Alignment.bottomRight,
        );
      }
      else {
        toastification.show(
          context: context,
          title: const Text('Dossard non valide'),
          autoCloseDuration: const Duration(seconds: 3),
          primaryColor: Colors.black,
          backgroundColor: Colors.red,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.cancel_outlined),
          closeOnClick: true,
          alignment: Alignment.bottomRight,
        );
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            dossard.value,
          ),
          Container(
            width: 160,
            margin: const EdgeInsets.all(10.0),
            child: TextField(
              keyboardType: TextInputType.number,
              controller: _controllerDossard,
              decoration: const InputDecoration(
                labelText: 'Dossard',
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          ),
          FloatingActionButton(
            onPressed: envoyer,
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}