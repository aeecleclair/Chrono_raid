import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class OngletCompilateur extends HookWidget {
  OngletCompilateur({super.key,});

  @override
  Widget build(BuildContext context) {

    void onPressed() {}

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: onPressed, child: Text('Classement')),
        ElevatedButton(onPressed: onPressed, child: Text('Temps intermédaire')),
        ElevatedButton(onPressed: onPressed, child: Text('Temps Manquants')),
      ],
    );
  }
}