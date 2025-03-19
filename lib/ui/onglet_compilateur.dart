import 'package:chrono_raid/tools/providers/last_syncro_date_provider.dart';
import 'package:chrono_raid/ui/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OngletCompilateur extends HookWidget {
  final WidgetRef ref;
  OngletCompilateur(this.ref, {super.key,});

  @override
  Widget build(BuildContext context) {
    final lastSynchroDate = ref.watch(lastSynchroDateProvider);
    final lastSynchroDateNotifier = ref.watch(lastSynchroDateProvider.notifier);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            synchronisation(lastSynchroDate);
            lastSynchroDateNotifier.editDate(DateTime.now().toIso8601String());
            download_csv();
          }, 
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Temps'),
              Icon(Icons.download),
            ]
          ),
        ),

        // ElevatedButton(onPressed: onPressed, child: Text('Temps intermédaires')),
        // ElevatedButton(onPressed: onPressed, child: Text('Temps Manquants')),
      ],
    );
  }
}