import 'package:chrono_raid/ui/database.dart';
import 'package:chrono_raid/ui/temps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OngletDossardUnique extends HookWidget {
  OngletDossardUnique({super.key,});

  final TextEditingController _controllerDossard = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dossard = useState('');
    final dbm = DatabaseManager();
    
    void envoyer() async {
      dossard.value = _controllerDossard.text;
      if (await dbm.valideDossard(dossard.value)) {
        _controllerDossard.clear();
        dbm.createTemps(Temps(int.parse(dossard.value), DateTime.now().toIso8601String(), await dbm.getParcoursByDossard(dossard.value)));
      }
      else {
        Fluttertoast.showToast(
          msg: "This is Center Short Toast",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
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