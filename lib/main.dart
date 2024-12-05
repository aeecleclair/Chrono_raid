import 'package:chrono_raid/ui/onglet_edit_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/onglet_dossard_unique.dart';
import 'ui/onglet_dossard_groupe.dart';
import 'ui/onglet_compte.dart';
import 'ui/onglet_edit_temps.dart';
import 'ui/onglet_remarque.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {

  // Initialize FFI
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;
 runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chrono raid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Chrono raid'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 6,
        child: Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.person),
                  child: Text('Départ simple')
                ),
                Tab(
                  icon: Icon(Icons.group),
                  child: Text('Départ groupé'),
                ),
                Tab(
                  icon: Icon(Icons.supervisor_account_outlined),
                  child: Text('Compte'),
                ),
                Tab(
                  icon: Icon(Icons.edit),
                  child: Text('Temps')
                ),
                Tab(
                  icon: Icon(Icons.edit),
                  child: Text('Actions')
                ),
                Tab(
                  icon: Icon(Icons.speaker_notes),
                  child: Text('Remarques/tests'),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Onglet départ dossard unique
              OngletDossardUnique(),

              // Onglet départ dossard groupe
              OngletDossardGroupe(),

              // Onglet compte dossard
              OngletCompte(),

              // Onglet consulte et edit temps
              OngletEditTemps(),
              
              // Onglet consulte et edit actions
              OngletEditAction(),

              // Onglet remarque
              OngletRemarque(),
            ],
          ),
        ),
      ),
    );
  }
}