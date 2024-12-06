import 'package:chrono_raid/ui/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:toastification/toastification.dart';


class OngletDossardGroupe extends HookWidget {
  OngletDossardGroupe({super.key,}); 

  Map dicoEpreuves = {'Découverte':["Trail 1", "VTT 2"], "Sportif":["Trail 1", "VTT 2", "Trail 4"], "Expert":["Trail 1", "VTT 2", "R&B 3", "Trail 4"]};

  @override
  Widget build(BuildContext context) {
    final info = useState('');
    final parcours = useState('Découverte');
    final epreuves = useState(dicoEpreuves[parcours.value]);
    final epreuveValue = useState(epreuves.value[0]);
    final dbm = DatabaseManager();

    void envoyer() async {
      String date = DateTime.now().toIso8601String();
      final result = (await dbm.createTempsGroupe(parcours.value, date)).toString();
      if (result.isEmpty) {
        toastification.show(
          context: context,
          title: const Text('Temps ajoutés !'),
          autoCloseDuration: const Duration(seconds: 3),
          primaryColor: Colors.black,
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.check_circle_outlined),
          closeOnClick: true,
          alignment: Alignment.bottomRight,
        );
      } else {
        toastification.show(
          context: context,
          title: Text(result),
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
      child: SizedBox(
        width: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              info.value,
            ),
            for (int i = 0; i <= 2; i++)
              RadioListTile(
                title: Text(
                    ['Découverte', 'Sportif', 'Expert'][i],
                  ),
                value: ['Découverte', 'Sportif', 'Expert'][i],
                groupValue: parcours.value,
                activeColor: Color(0xFF6200EE),
                onChanged: (value) {
                  parcours.value = value.toString();
                  epreuves.value = dicoEpreuves[parcours.value];
                  epreuveValue.value = epreuves.value[0];
                },
              ),

            const SizedBox(height: 20),

            DropdownButton(
              value: epreuveValue.value,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: epreuves.value.map<DropdownMenuItem<Object>>((String epreuve) {
                return DropdownMenuItem(
                  value: epreuve,
                  child: Text(epreuve),
                );
              }).toList(),
              onChanged: (value) { 
                epreuveValue.value = value.toString();
              },
            ),

            const SizedBox(height: 30),

            FloatingActionButton(
              onPressed: envoyer,
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}