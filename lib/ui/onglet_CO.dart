import 'package:chrono_raid/ui/database.dart';
import 'package:chrono_raid/tools/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:toastification/toastification.dart';

import 'balise.dart';


class OngletCO extends HookWidget {
  OngletCO({super.key,}); 

  final TextEditingController controllerDossard = TextEditingController();
  final TextEditingController controllerBalise = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();
    
    void envoyer() async {
      String dossard_str = controllerDossard.text;
      String nb_balise_str = controllerBalise.text;
      controllerBalise.clear();
      controllerDossard.clear();
      
      if (dossard_str != '' && await dbm.valideDossard(dossard_str)) {
        if (nb_balise_str != '') {
          final result = await dbm.createBalise(Balise(int.parse(dossard_str), int.parse(nb_balise_str)));
          if (result.isNotEmpty && result != nb_balise_str) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Editer balises CO dossard : $dossard_str'),
                  content: 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [Text("Ancien"), Text(result)],
                        ),
                        SizedBox(height: 20,),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [Text("Nouveau"), Text(nb_balise_str)],
                        ),
                      ],
                    ),
                  actions: [
                    ElevatedButton(
                      child: const Text("Garder l'ancien"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      child: const Text("Changer"),
                      onPressed: () {
                        dbm.editBalise(dossard_str, nb_balise_str);
                        Navigator.of(context).pop();
                      },
                    ),
                  ]
                );
              }
            );
          } else{
            toastification.show(
              context: context,
              title: const Text('Balise ajoutée !'),
              autoCloseDuration: const Duration(seconds: 3),
              primaryColor: Colors.black,
              backgroundColor: Colors.green,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.check_circle_outlined),
              closeOnClick: true,
              alignment: kIsMobile ? Alignment.topLeft : Alignment.bottomRight,
            );
          }
        } else {
          toastification.show(
            context: context,
            title: const Text('Nombre balise non valide'),
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
          alignment: kIsMobile ? Alignment.topLeft : Alignment.bottomRight,
        );
      }
    }

    void consulter() async {
      final balises = await dbm.getBalises();
      final scrollController = ScrollController();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Consulter balises CO'),
            content: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.vertical,
                child: (balises.isNotEmpty)?
                  SizedBox(
                    width: 500,
                    height: 50*balises.length.toDouble(),
                    child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [Text('Dossard'), Text('Nombre balises'),],
                        ),
                        for (var b in balises) ...[
                          Divider(thickness: 1,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                            Text(b.dossard.toString()),
                            Text(b.nb_balise.toString()),
                          ],),
                        ],
                      ],
                    ),
                  )
                  : Text('Pas de balises'),
              ),
            ),
            actions: [
              ElevatedButton(
                child: const Text("Fermer"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ]
          );
        }
      );

    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
        Container(
          width: 200,
          margin: const EdgeInsets.all(10.0),
          child: TextField(
            keyboardType: TextInputType.number,
            controller: controllerBalise,
            decoration: const InputDecoration(
              labelText: 'Nombre balises',
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
        ),
        SizedBox(height: 20,),
        SizedBox(
          width: 150,
          child: FloatingActionButton(
            onPressed: envoyer,
            child: const Text('Envoyer'),
          ),
        ),
        SizedBox(height: 20,),
        SizedBox(
          width: 150,
          child: FloatingActionButton(
            onPressed: consulter,
            child: const Text('Consulter'),
          ),
        ),
      ],
    );
  }
}