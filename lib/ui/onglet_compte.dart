import 'dart:convert';

import 'package:chrono_raid/ui/equipes.dart';
import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/ui/temps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletCompte extends HookWidget {
  OngletCompte({super.key,});

  @override
  Widget build(BuildContext context) {
    final test = useState('');
    final dbm = DatabaseManager();

    void envoyer() async {
      print('a');
      final tamere = await readJsonEpreuves();
      test.value = tamere["Expert"].toString();

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