
import 'package:chrono_raid/login/tools/constants.dart';
import 'package:chrono_raid/login/ui/components/sign_in_up_bar.dart';
import 'package:chrono_raid/main.dart';
import 'package:chrono_raid/tools/constants.dart';
import 'package:chrono_raid/tools/functions.dart';
import 'package:chrono_raid/tools/providers/path_forwarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chrono_raid/auth/providers/openid_provider.dart';
import 'package:chrono_raid/tools/providers/last_syncro_date_provider.dart';
import 'package:chrono_raid/ui/database.dart';
import 'package:chrono_raid/ui/functions.dart';
import 'package:qlevar_router/qlevar_router.dart';

class SynchronizationButton extends StatelessWidget {
  const SynchronizationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.sync),
      onPressed: () => showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => SynchronizationDialog(),
      ),
    );
  }
}

class SynchronizationDialog extends ConsumerWidget {
  const SynchronizationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSynchroDate = ref.watch(lastSynchroDateProvider);
    final lastSynchroDateNotifier = ref.watch(lastSynchroDateProvider.notifier);
    final token = ref.watch(tokenProvider);
    final authNotifier = ref.watch(authTokenProvider.notifier);
    final pathForwarding = ref.read(pathForwardingProvider);

    void verifAndSynchro() async {
      final dbm = DatabaseManager();
      final bool jsonChanged = await jsonHasChanged();

      if (jsonChanged) {
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text(
                    "Les fichiers de configuration ont changés, des erreurs peuvent apparaitre, il est recommandé de réinitialiser la base de données locale pour pouvoir synchroniser."),
                actions: [
                  TextButton(
                      child: const Text("Ignorer"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        return;
                      }),
                  ElevatedButton(
                    onPressed: () async {
                      bool confirmReset = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirmer la réinitialisation'),
                            content: Text(
                                'Êtes-vous sûr de vouloir réinitialiser la base de données locale et synchroniser ?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Annuler'),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                              TextButton(
                                child: Text('Confirmer'),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmReset == true) {
                        try {
                          await dbm.resetBDD();
                          notif(context, 'Base de données réinitialisée !',
                              Colors.green, Icons.check_circle_outline);
                        } catch (e) {
                          notif(context, e.toString(), Colors.red,
                              Icons.cancel_outlined);
                        }

                        try {
                          await jsonUpdate();
                          notif(
                              context,
                              'Fichier de configuration mis à jour !',
                              Colors.green,
                              Icons.check_circle_outline);
                        } catch (e) {
                          notif(context, e.toString(), Colors.red,
                              Icons.cancel_outlined);
                        }

                        try {
                          await synchronisation(lastSynchroDate);
                          lastSynchroDateNotifier
                              .editDate(DateTime.now().toIso8601String());
                          notif(context, 'Synchronisation réussie !',
                              Colors.green, Icons.check_circle_outline);
                        } catch (e) {
                          notif(context, e.toString(), Colors.red,
                              Icons.cancel_outlined);
                        }

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => HomePage()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                    child: const Text(
                        'Modification des fichiers de configuration'),
                  ),
                ],
              );
            });
      } else {
        try {
          await synchronisation(lastSynchroDate);
          lastSynchroDateNotifier.editDate(DateTime.now().toIso8601String());
          notif(context, 'Synchronisation réussie !', Colors.green,
              Icons.check_circle_outline);
        } catch (e) {
          notif(context, 'Erreur de synchronisation: $e', Colors.red,
              Icons.cancel_outlined);
        }
      }
    }

    return AlertDialog(
      scrollable: false,
      title: Text('Synchronisation'),
      content: Container(
        child: token.isEmpty
            ? SignInUpBar(
                isLoading: ref.watch(loadingProvider).maybeWhen(
                      data: (data) => data,
                      orElse: () => false,
                    ),
                label: LoginTextConstants.signIn,
                onPressed: () async {
                  await authNotifier.getTokenFromRequest();
                  ref.watch(authTokenProvider).when(
                        data: (token) {
                          QR.to(pathForwarding.path);
                        },
                        error: (e, s) {
                          print(e);
                          displayToast(
                            context,
                            TypeMsg.error,
                            LoginTextConstants.loginFailed,
                          );
                        },
                        loading: () {},
                      );
                },
                color: ColorConstants.background2,
                icon: const Icon(
                  Icons.arrow_right_alt_outlined,
                  color: ColorConstants.background2,
                  size: 35.0,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: verifAndSynchro,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.sync), Text('Synchronisation')],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: verifAndSynchro,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download),
                        Text('Télécharger les temps')
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Divider(),
                  SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        authNotifier.deleteToken();
                      } catch (e) {
                        notif(context, e.toString(), Colors.red,
                            Icons.cancel_outlined);
                      }
                    },
                    child: const Text("Se déconnecter"),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ResetLocalBaseButton(),
                ],
              ),
      ),
      actions: [
        ElevatedButton(
          child: const Text("Fermer"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class ResetLocalBaseButton extends StatelessWidget {
  const ResetLocalBaseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dbm = DatabaseManager();

    return ElevatedButton(
      onPressed: () async {
        bool confirmReset = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirmer la réinitialisation'),
              content: Text(
                  'Êtes-vous sûr de vouloir réinitialiser la base de données locale ?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Confirmer'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
        if (confirmReset == true) {
          try {
            await dbm.resetBDD();
            notif(context, 'Base de données réinitialisée !', Colors.green,
                Icons.check_circle_outline);
          } catch (e) {
            notif(context, e.toString(), Colors.red, Icons.cancel_outlined);
          }
        }
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.delete), Text('Réinitialiser la base locale')],
      ),
    );
  }
}
