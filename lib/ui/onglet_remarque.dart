import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/ui/remarque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletRemarque extends HookWidget {
  final String ravito;
  OngletRemarque(this.ravito, {super.key,});
  final TextEditingController _controllerRemarque = TextEditingController();

  @override
  Widget build(BuildContext context) {

    void envoyer() async {
      final dbm = DatabaseManager();
      String remarque_text = _controllerRemarque.text;
      await dbm.createRemarque(Remarque(DateTime.now().toIso8601String(), ravito, remarque_text));
      _controllerRemarque.clear();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(24),
            child: SizedBox(
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