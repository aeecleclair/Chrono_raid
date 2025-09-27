import 'package:chrono_raid/tools/constants.dart';
import 'package:chrono_raid/ui/json_folder_storage.dart';
import 'package:chrono_raid/ui/synchronization_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'ui/onglet_dossard_unique.dart';
import 'ui/onglet_dossard_groupe.dart';
import 'ui/onglet_compte.dart';
import 'ui/onglet_edit_temps.dart';
import 'ui/onglet_remarque.dart';
import 'ui/functions.dart';
import 'ui/onglet_edit_action.dart';
import 'ui/page_admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await json_initialisation();

  if (kIsDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      scrollBehavior: CustomScrollBehavior(),
      home: HomePage(),
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
      };
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text('Page d\'Accueil'),
                    SynchronizationButton(),
                  ]),
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
                            MaterialPageRoute(
                                builder: (context) => MainPage(r)),
                          );
                        },
                        child: Text(r),
                      ),
                  ]),
            ),
          );
        });
  }
}

class MainPage extends HookConsumerWidget {
  final String ravito;
  const MainPage(this.ravito, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ravito == 'Admin') {
      return PageAdmin(ref: ref);
    }

    return MaterialApp(
      home: DefaultTabController(
        length: (kIsMobile ? 5 : 6),
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
                    icon: const Icon(Icons.arrow_back)),
                Text(ravito),
                SynchronizationButton(),
              ],
            ),
          ),
          body: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: kIsMobile
                ? null
                : AppBar(
                    title: null,
                    bottom: buildTabs(),
                  ),
            body: buildTabsContent(ravito),
            bottomNavigationBar: kIsMobile ? buildTabs() : null,
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget buildTabs() {
  return TabBar(
    tabs: [
      for (final tab in [
        if (kIsMobile) ...[
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

Widget buildTabsContent(String ravito) {
  final editTempsScrollController = ScrollController();
  return Column(children: [
    Expanded(
      child: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        children: [
          if (kIsMobile) ...[
            // Onglet fusionné dossard unique et groupe
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OngletDossardUnique(ravito),
                Divider(
                  thickness: 1,
                ),
                OngletDossardGroupe(ravito),
              ],
            ),
          ] else ...[
            // Onglet départ dossard unique
            OngletDossardUnique(ravito),

            // Onglet départ dossard groupe
            OngletDossardGroupe(ravito),
          ],

          // Onglet compte dossard
          SingleChildScrollView(child: OngletCompte(ravito)),

          // Onglet consulte et edit temps
          SingleChildScrollView(
              controller: editTempsScrollController,
              child: OngletEditTemps(ravito, editTempsScrollController)),

          // Onglet consulte et edit actions
          SingleChildScrollView(child: OngletEditAction(ravito)),

          // Onglet remarque
          SingleChildScrollView(child: OngletRemarque(ravito)),
        ],
      ),
    ),
    if (kIsMobile) Divider(thickness: 1),
  ]);
}
