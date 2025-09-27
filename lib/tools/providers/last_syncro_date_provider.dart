import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastSynchroDateNotifier extends StateNotifier<String> {
  LastSynchroDateNotifier() : super('2000-01-01T00:00:00.000000');

  void editDate(String new_date) {
    state = new_date;
  }
}

final lastSynchroDateProvider =
    StateNotifierProvider<LastSynchroDateNotifier, String>((ref) {
  return LastSynchroDateNotifier();
});
