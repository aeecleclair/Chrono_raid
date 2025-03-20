import 'package:chrono_raid/auth/providers/openid_provider.dart';
import 'package:chrono_raid/login/ui/app_sign_in.dart';
import 'package:chrono_raid/tools/constants.dart';
import 'package:chrono_raid/tools/providers/last_syncro_date_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'ui/onglet_dossard_unique.dart';
import 'ui/onglet_dossard_groupe.dart';
import 'ui/onglet_compte.dart';
import 'ui/onglet_edit_temps.dart';
import 'ui/onglet_remarque.dart';
import 'ui/onglet_CO.dart';
import 'ui/functions.dart';
import 'ui/onglet_edit_action.dart';
import 'ui/page_admin.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    ProviderScope(
      child: MyApp()
    )
  );
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenProvider);
    if (token.isEmpty) {
      return AppSignIn();
    }
    final lastSynchroDate = ref.watch(lastSynchroDateProvider);
    final lastSynchroDateNotifier = ref.watch(lastSynchroDateProvider.notifier);
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
              children: [
                Text('Page d\'Accueil'),
                IconButton(
                  onPressed: () {
                    synchronisation(lastSynchroDate);
                    lastSynchroDateNotifier.editDate(DateTime.now().toIso8601String());
                  }, 
                  icon:const Icon(Icons.sync)
                ),
              ]
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

class MainPage extends HookConsumerWidget {
  final String ravito;
  const MainPage(this.ravito, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSynchroDate = ref.watch(lastSynchroDateProvider);
    final lastSynchroDateNotifier = ref.watch(lastSynchroDateProvider.notifier);
    if (ravito == 'Admin') {
      return PageAdmin(ref: ref);
    }

    return FutureBuilder(
      future: isCO(ravito),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final CO = snapshot.data!;
        return MaterialApp(
          home: DefaultTabController(
            length: (kIsMobile? 5 : 6) + (CO? 1 : 0),
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
                      Text(ravito),
                      IconButton(
                        onPressed: () {
                          synchronisation(lastSynchroDate);
                          lastSynchroDateNotifier.editDate(DateTime.now().toIso8601String());
                        }, 
                        icon:const Icon(Icons.sync)
                      ),
                    ],
                  ),
              ),
              body: Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: kIsMobile ? null : AppBar(
                  title: null,
                  bottom: buildTabs(CO),
                ),
                body: buildTabsContent(CO, ravito),
                bottomNavigationBar: kIsMobile ? buildTabs(CO) : null,
              ),
            ),
          ),
        );
      }
    );
  }

  PreferredSizeWidget buildTabs(bool CO) {
    return TabBar(
      tabs:[
        for (final tab in [
          if (kIsMobile) ...[
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

  Widget buildTabsContent(bool CO, String ravito) {
    final editTempsScrollController = ScrollController();
    return Column(
      children: [
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
                    Divider(thickness: 1,),
                    OngletDossardGroupe(ravito),
                  ],
                ),
              ] else ...[
                // Onglet départ dossard unique
                OngletDossardUnique(ravito),

                // Onglet départ dossard groupe
                OngletDossardGroupe(ravito),
              ],

              // Onglet CO
              if (CO) OngletCO(),
    
              // Onglet compte dossard
              SingleChildScrollView(child: OngletCompte(ravito)),
    
              // Onglet consulte et edit temps
              SingleChildScrollView(
                controller: editTempsScrollController,
                child: OngletEditTemps(ravito, editTempsScrollController)
              ),
              
              // Onglet consulte et edit actions
              SingleChildScrollView(child: OngletEditAction(ravito)),
    
              // Onglet remarque
              SingleChildScrollView(child: OngletRemarque(ravito)),
            ],
          ),
        ),
        if (kIsMobile) Divider(thickness: 1),
      ]
    );
  }
}