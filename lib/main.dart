import 'dart:io';

import 'package:chrono_raid/ui/onglet_CO.dart';
import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/ui/onglet_edit_action.dart';
import 'package:chrono_raid/ui/page_admin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getRavitos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucune donnée disponible'));
        }
        final data = snapshot.data!;
        data.add('Admin');

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Text('Page d\'Accueil'), Icon(Icons.sync)]
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var r in data)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainPage(r)),
                      );
                    },
                    child: Text(r),
                  ),
              ]
            ),
          ),
        );
      } 
    );
  }
}

class MainPage extends StatefulWidget {
  final String ravito;
  const MainPage(this.ravito, {super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

    if (widget.ravito == 'Admin') {
      return PageAdmin();
    }

    return FutureBuilder(
      future: isCO(widget.ravito),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final CO = snapshot.data!;
        return MaterialApp(
          home: DefaultTabController(
            length: (isMobile? 5 : 6) + (CO? 1 : 0),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        }, 
                        icon:const Icon(Icons.arrow_back)
                      ),
                      Text(widget.ravito),
                      IconButton(
                        onPressed: () {}, 
                        icon:const Icon(Icons.sync)
                      ),
                    ],
                  ),
              ),
              body: Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: isMobile ? null : AppBar(
                  title: null,
                  bottom: buildTabs(isMobile, CO),
                ),
                body: buildTabsContent(isMobile, CO, widget.ravito),
                bottomNavigationBar: isMobile ? buildTabs(isMobile, CO) : null,
              ),
            ),
          ),
        );
      }
    );
  }

  PreferredSizeWidget buildTabs(bool isMobile, bool CO) {
    return TabBar(
      tabs:[
        for (final tab in [
          if (isMobile) ...[
            {'icon': Icons.person, 'text': 'Départ'},
          ] else ...[
            {'icon': Icons.person, 'text': 'Départ simple'},
            {'icon': Icons.group, 'text': 'Départ groupé'},
          ],
          if (CO) ...[
            {'icon': Icons.map_rounded, 'text': "Course d'orientation"},
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

  Widget buildTabsContent(bool isMobile, bool CO, String ravito) {
    if (isMobile) {
      return Column(
        children: [
          Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                // Onglet fusionné dossard unique et groupe
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OngletDossardUnique(ravito),
                    Divider(thickness: 1,),
                    OngletDossardGroupe(ravito),
                  ],
                ),

                // Onglet CO
                if (CO) OngletCO(),
      
                // Onglet compte dossard
                OngletCompte(ravito),
      
                // Onglet consulte et edit temps
                OngletEditTemps(ravito),
                
                // Onglet consulte et edit actions
                OngletEditAction(ravito),
      
                // Onglet remarque
                OngletRemarque(ravito),
              ],
            ),
          ),
          Divider(thickness: 1),
        ]
      );
    }
    return  TabBarView(
      children: [
        // Onglet départ dossard unique
        OngletDossardUnique(ravito),

        // Onglet départ dossard groupe
        OngletDossardGroupe(ravito),

        // Onglet CO
        if (CO) OngletCO(),

        // Onglet compte dossard
        OngletCompte(ravito),

        // Onglet consulte et edit temps
        OngletEditTemps(ravito),
        
        // Onglet consulte et edit actions
        OngletEditAction(ravito),

        // Onglet remarque
        OngletRemarque(ravito),
      ],
    );
  }
}