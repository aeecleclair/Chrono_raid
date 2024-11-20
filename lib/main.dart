import 'package:chrono_raid/ui/onglet_compte.dart';
import 'package:chrono_raid/ui/onglet_test.dart';
import 'package:chrono_raid/ui/onglet_dossard_groupe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/onglet_dossard_unique.dart';

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
        length: 4,
        child: Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.person)),
                Tab(icon: Icon(Icons.group)),
                Tab(icon: Icon(Icons.supervisor_account_outlined)),
                Tab(icon: Icon(Icons.speaker_notes)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Onglet dossard unique
              OngletDossardUnique(),

              // Onglet dossard groupe
              OngletDossardGroupe(),

              // Onglet compte
              OngletCompte(),
              
              // Onglet test
              OngletTest(),
            ],
          ),
        ),
      ),
    );
  }
}