import 'package:chrono_raid/ui/database.dart';
import 'package:chrono_raid/ui/popup_edit_temps.dart';
import 'package:chrono_raid/ui/temps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:toastification/toastification.dart';

class OngletDossardUnique extends HookWidget {
  final String ravito;
  OngletDossardUnique(this.ravito, {super.key,});

  final TextEditingController controllerDossard = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dossard = useState('');
    final focusNode = useFocusNode();
    final focusNode2 = useFocusNode();
    final dbm = DatabaseManager();
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    
    void envoyer() async {
      String dossard_str = controllerDossard.text;
      dossard.value = dossard_str;
      if (dossard_str != '' && await dbm.valideDossard(dossard_str)) {
        controllerDossard.clear();
        final String now = DateTime.now().toIso8601String();
        final result = await dbm.createTemps(Temps(int.parse(dossard_str), now, await dbm.getParcoursByDossard(dossard_str), ravito));
        if (result.toString() == 'Erreur') {
          toastification.show(
            context: context,
            title: Container(
              width: 300,
              height: 90,
              padding: EdgeInsets.all(16),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ligne du dossard pleine',),
                  Text('Temps non ajouté',),
                  Text('Cliquer pour résoudre',),
                ],
              ),
            ),
            primaryColor: Colors.black,
            backgroundColor: Colors.red,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.cancel_outlined),
            closeOnClick: true,
            alignment: isMobile ? Alignment.topLeft : Alignment.bottomRight,
            callbacks: ToastificationCallbacks(
              onTap: (toastItem) {
                showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) {return PopupEditTemps(dossard: dossard_str, ravito: ravito, date: now);});
              },
            ),
            showProgressBar: false,
          );
        }
        else {
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
        }
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
          alignment: isMobile ? Alignment.topLeft : Alignment.bottomRight,
        );
      }
    }

    return Focus(
        focusNode: focusNode,
        autofocus: true,
        child: KeyboardListener(
          focusNode: focusNode2,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
              envoyer();
            }
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dossard.value,
                ),
                Container(
                  width: 200,
                  margin: const EdgeInsets.all(10.0),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: controllerDossard,
                    decoration: const InputDecoration(
                      labelText: 'Dossard',
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
                SizedBox(height: 20,),
                FloatingActionButton(
                  onPressed: envoyer,
                  child: const Text('Envoyer'),
                ),
              ],
            ),
          ),
        )
    );
  }
}