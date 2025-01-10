
import 'package:chrono_raid/ui/functions.dart';
import 'package:chrono_raid/ui/onglet_compte.dart';
import 'package:chrono_raid/ui/onglet_edit_temps.dart';
import 'package:chrono_raid/ui/onglet_temps_manquants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PageAdmin extends StatefulHookWidget {
  const PageAdmin({super.key});

  @override
  State<PageAdmin> createState() => _MainPageState();
}

class _MainPageState extends State<PageAdmin> {
  @override
  Widget build(BuildContext context) {
    final bool isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
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
                  IconButton(
                    onPressed: () {}, 
                    icon:const Icon(Icons.sync)
                  ),
                ],
              ),
          ),
          body: Scaffold(
            appBar: isMobile ? null : AppBar(
              title: null,
              bottom: buildTabs(isMobile),
            ),
            body: buildTabsContent(isMobile),
            bottomNavigationBar: isMobile ? buildTabs(isMobile) : null,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget buildTabs(bool isMobile) {
    return TabBar(
      tabs:[
        for (final tab in [
          {'icon': Icons.supervisor_account_outlined, 'text': 'Compte'},
          {'icon': Icons.edit, 'text': 'Temps'},
          {'icon': Icons.access_time, 'text': 'Temps Manquants'},
          //{'icon': Icons.speaker_notes, 'text': 'Remarques'},
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

  Widget buildTabsContent(bool isMobile) {
    if (isMobile) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  // Onglet compte dossard
                  OngletCompte('admin'),
        
                  // Onglet consulte et edit temps
                  OngletEditTemps('admin'),

                  // Onglet temps manquants
                  OngletTempsManquants(),
        
                  // Onglet remarque
                  //OngletRemarque('admin'),
                ],
              ),
            ),
            Divider(thickness: 1),
          ]
        ),
      );
    }
    final ravitoValue = useState('admin');
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
        
        return TabBarView(
          children: [
            // Onglet compte dossard
            Column(
              children: [
                DropdownButton(
                  value: ravitoValue.value,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: ravitos.map<DropdownMenuItem<Object>>((String r) {
                    return DropdownMenuItem(
                      value: r=='Tout'?'admin':r,
                      child: Text(r),
                    );
                  }).toList(),
                  onChanged: (value) { 
                    ravitoValue.value = value.toString();
                  },
                ),
                OngletCompte(ravitoValue.value),
              ],
            ),

            // Onglet consulte et edit temps
            OngletEditTemps('admin'),

            // Onglet temps manquants
            OngletTempsManquants(),

            // Onglet remarque
            //OngletRemarque('admin'),
          ],
        );
      }
    );
  }
}