import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'database.dart';

class OngletTempsManquants extends HookWidget {
  OngletTempsManquants({super.key,});

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();

    return FutureBuilder(
      future: dbm.compteTempsManquants(),
      builder: (context, snapshot) {
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return Center(child: CircularProgressIndicator());
        // } else if (snapshot.hasError) {
        //   return Center(child: Text('Erreur: ${snapshot.error}'));
        // } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        //   return Center(child: Text('Aucune donnée disponible'));
        // }

        final data = snapshot.data;
        
        return Center(
          child: Text(
            'a'
          ),
        );
      },
    );
  }
}