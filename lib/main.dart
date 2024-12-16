import 'dart:io';

import 'package:chrono_raid/ui/onglet_edit_action.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'ui/onglet_dossard_unique.dart';
import 'ui/onglet_dossard_groupe.dart';
import 'ui/onglet_compte.dart';
import 'ui/onglet_edit_temps.dart';
import 'ui/onglet_remarque.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
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
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

    return MaterialApp(
      home: DefaultTabController(
        length: isMobile? 5 : 6,
        child: Scaffold(
          appBar: isMobile ? null : AppBar(
            title: null,
            bottom: buildTabs(isMobile),
          ),
          body: buildTabsContent(isMobile),
          bottomNavigationBar: isMobile ? buildTabs(isMobile) : null,
        ),
      ),
    );
  }

  PreferredSizeWidget buildTabs(bool isMobile) {
    return TabBar(
      tabs:[
        for (final tab in [
          if (isMobile) ...[
            {'icon': Icons.person, 'text': 'Départ'},
          ] else ...[
            {'icon': Icons.person, 'text': 'Départ simple'},
            {'icon': Icons.group, 'text': 'Départ groupé'},
          ],
          {'icon': Icons.supervisor_account_outlined, 'text': 'Compte'},
          {'icon': Icons.edit, 'text': 'Temps'},
          {'icon': Icons.edit, 'text': 'Actions'},
          {'icon': Icons.speaker_notes, 'text': 'Remarques'},
        ])
          Tab(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 20,
              runSpacing: 5,
              children: [
                Icon(tab['icon'] as IconData, size: 24),
                Text(
                  tab['text'] as String,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
      labelPadding: EdgeInsets.only(bottom: 25),
    );
  }

  Widget buildTabsContent(bool isMobile){
    if (isMobile) {
      return  Column(
        children: [
          SizedBox(height: 60),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Onglet fusionné dossard unique et groupe
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height/3-10,
                        width: 160,
                        child: OngletDossardUnique(),
                      ),
                      Divider(thickness: 1,),
                      OngletDossardGroupe(),
                    ],
                  ),
                ),

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
          Divider(thickness: 1),
        ]
      );
    }
    return TabBarView(
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
    );
  }
}