import 'package:chrono_raid/ui/database.dart';
import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/tools/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:toastification/toastification.dart';

class OngletDossardGroupe extends HookWidget {
  final String ravito;
  const OngletDossardGroupe(this.ravito, {super.key,}); 

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();
    final parcours = useState<String?>(null);

    void envoyer() async {
      try {
        String date = DateTime.now().toIso8601String();
        await dbm.createTempsGroupe(parcours.value!, date, ravito);
        toastification.show(
          context: context,
          title: const Text('Temps ajoutés !'),
          autoCloseDuration: const Duration(seconds: 3),
          primaryColor: Colors.black,
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.check_circle_outlined),
          closeOnClick: true,
          alignment: kIsMobile ? Alignment.topLeft : Alignment.bottomRight,
        );
      } catch(e) {
        toastification.show(
          context: context,
          title: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 3),
          primaryColor: Colors.black,
          backgroundColor: Colors.red,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.cancel_outlined),
          closeOnClick: true,
          alignment: kIsMobile ? Alignment.topLeft : Alignment.bottomRight,
        );
      }
    }

    return FutureBuilder<List<String>>(
      future: getParcours(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final listParcours = snapshot.data ?? [];
        if (listParcours.isEmpty) {
          return const Center(child: Text('Aucun parcours disponible'));
        }
        
        if (parcours.value == null && listParcours.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            parcours.value = listParcours[0];
          });
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var p in listParcours)
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
      },
    );
  }
}
