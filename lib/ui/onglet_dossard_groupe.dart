import 'package:chrono_raid/ui/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:toastification/toastification.dart';


class OngletDossardGroupe extends HookWidget {
  final String ravito;
  const OngletDossardGroupe(this.ravito, {super.key,}); 

  @override
  Widget build(BuildContext context) {
    final parcours = useState('Découverte');
    final dbm = DatabaseManager();
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

    void envoyer() async {
      String date = DateTime.now().toIso8601String();
      final result = (await dbm.createTempsGroupe(parcours.value, date, ravito)).toString();
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
          alignment: isMobile ? Alignment.topLeft : Alignment.bottomRight,
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
          alignment: isMobile ? Alignment.topLeft : Alignment.bottomRight,
        );
      }
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var p in ['Découverte', 'Sportif', 'Expert'])
            SizedBox(
              width: 200,
              child: RadioListTile(
                title: Text(p),
                value: p,
                groupValue: parcours.value,
                activeColor: Color(0xFF6200EE),
                onChanged: (value) {
                  parcours.value = value.toString();
                },
              ),
            ),
          
          const SizedBox(height: 20),
          
          FloatingActionButton(
            onPressed: envoyer,
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}