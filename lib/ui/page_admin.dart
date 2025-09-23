import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/ui/onglet_compte.dart';
import 'package:chrono_raid/ui/onglet_consulte_remarque.dart';
import 'package:chrono_raid/ui/onglet_edit_temps.dart';
import 'package:chrono_raid/ui/onglet_temps_manquants.dart';
import 'package:chrono_raid/tools/constants.dart';
import 'package:chrono_raid/ui/synchronization_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageAdmin extends StatefulHookWidget {
  final WidgetRef ref;

  const PageAdmin({
    required this.ref,
    super.key
  });

  @override
  State<PageAdmin> createState() => _MainPageState();
}

class _MainPageState extends State<PageAdmin> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
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
                  Text('Admin'),
                  SynchronizationButton(),
                ],
              ),
          ),
          body: Scaffold(
            appBar: kIsMobile ? null : AppBar(
              title: null,
              bottom: buildTabs(kIsMobile),
            ),
            body: buildTabsContent(kIsMobile),
            bottomNavigationBar: kIsMobile ? buildTabs(kIsMobile) : null,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget buildTabs(bool kIsMobile) {
    return TabBar(
      tabs:[
        for (final tab in [
          {'icon': Icons.supervisor_account_outlined, 'text': 'Compte'},
          {'icon': Icons.edit, 'text': 'Temps'},
          {'icon': Icons.speaker_notes, 'text': 'Remarques'},
          {'icon': Icons.access_time, 'text': 'Temps Manquants'},
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

  Widget buildTabsContent(bool kIsMobile) {
    if (kIsMobile) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            Expanded(
              child: Tabs()
            ),
            Divider(thickness: 1),
          ]
        ),
      );
    }
    return Tabs();
  }

  Widget Tabs() {
    final ravitoValue = [useState('admin'), useState('admin'), useState('admin')];

    return FutureBuilder(
      future: getRavitos(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucune donnée disponible'));
        }

        var ravitos = snapshot.data!;
        ravitos = ravitos + ['Tout'];
        
        final editTempsScrollController = ScrollController();
        
        List Onglets = [
          OngletCompte(ravitoValue[0].value), // Onglet compte dossard
          OngletEditTemps(ravitoValue[1].value, editTempsScrollController), // Onglet consulte et edit temps
          OngletConsulteRemarque(ravitoValue[2].value), // Onglet remarque
        ];

        return TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            for (var i in List.generate(Onglets.length, (i) => i)) ... [
              SingleChildScrollView(
                controller: i==1? editTempsScrollController : null,
                child: Column(
                  children: [
                    DropdownButton(
                      value: ravitoValue[i].value,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: ravitos.map<DropdownMenuItem<Object>>((String r) {
                        return DropdownMenuItem(
                          value: r=='Tout'?'admin':r,
                          child: Text(r),
                        );
                      }).toList(),
                      onChanged: (value) { 
                        ravitoValue[i].value = value.toString();
                      },
                    ),
                    Onglets[i],
                  ],
                ),
              ),
            ],
        
            // Onglet temps manquants
            SingleChildScrollView(child: OngletTempsManquants()),
          ],
        );
      }
    );
  }
}