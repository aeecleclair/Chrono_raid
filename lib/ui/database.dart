import 'package:chrono_raid/ui/functions.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'temps.dart';
import 'equipes.dart';
import 'action.dart';
import 'remarque.dart';
import 'balise.dart';

// le gestionnaire de base de donnée
class DatabaseManager {
  DatabaseManager._init();

  DatabaseManager();

  // L'instance, l'accès pour les autres classes à la base de donnée
  static final DatabaseManager instance = DatabaseManager._init();

  // La base de donnée
  static Database? _database;

  static const String filePath = 'database.db';

  // La conversion des types dart en type SQL
  final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  final intType = 'INTEGER NOT NULL';
  final stringType = 'TEXT NOT NULL';
  final doubleType = 'REAL NOT NULL';

  // Récupère la base de donnée si elle ne l'était pas déjà
  Future<Database> get database async => await _initDB(); //_database ??= await _initDB();

  Future<Database> _initDB() async {
    /**
     * Ouvre la base de donnée
     *
     * result :
     *     - Future<Database>
     */
    // On récupère le chemin vers la base de donné
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // await deleteDatabase(path);
    // print('db supprimée');

    // On ouvre la basse de donnée
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    /**
     * Crée les tables dans la base de donnée
     *
     * param :
     *     - db (Database)
     *     - version (int)
    */

    // Crée les tables

    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableEquipes (
        ${EquipesField.dossard} $intType,
        ${EquipesField.parcours} $stringType
    );
    ''');
    final value = await readJsonEquipes();
    final List<Map<String,String>> equipes = value;
    for (int i=0; i<equipes.length; i++) {
      final Map<String,String> json = equipes[i];
      await db.insert(tableEquipes, json); 
    }

    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableTemps (
        ${TempsField.id} $stringType,
        ${TempsField.dossard} $intType,
        ${TempsField.date} $stringType,
        ${TempsField.parcours} $stringType,
        ${TempsField.ravito} $stringType,
        ${TempsField.status} $intType,
        ${TempsField.last_modification_date} $stringType
    );
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableAction (
        ${ActionField.id} $stringType,
        ${ActionField.type} $stringType,
        ${ActionField.ravito} $stringType,
        ${ActionField.date} $stringType,
        ${ActionField.temps_id} $stringType,
        ${ActionField.parcours} $stringType,
        ${ActionField.dossard} $stringType,
        ${ActionField.ancien_temps} $stringType,
        ${ActionField.nouveau_temps} $stringType
    );
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableRemarque (
        ${RemarqueField.id} $stringType,
        ${RemarqueField.date} $stringType,
        ${RemarqueField.ravito} $stringType,
        ${RemarqueField.texte} $stringType
    );
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableBalise (
        ${BaliseField.dossard} $intType,
        ${BaliseField.nb_balise} $intType
    );
    ''');
  }

  /// General cruds

  Future<String> getParcoursByDossard(String dossard) async{
    final db = await instance.database;
    final List<Map<String, Object?>> result = await db.query(tableEquipes, columns: ['parcours'], where: 'dossard=$dossard');
    return result[0]["parcours"].toString();
  }

  Future<bool> valideDossard(String dossard) async{
    final db = await instance.database;
    final List<Map<String, Object?>> result = await db.query(tableEquipes, where: 'dossard=$dossard');
    return result.isNotEmpty;
  }

  Future<List<Equipes>> getEquipes(String? parcours) async {
    final db = await instance.database;
    const orderBy = '${EquipesField.dossard} ASC';
    final List<Map<String, Object?>> result;
    if (parcours == null) {
      result = await db.query(tableEquipes, orderBy: orderBy);
    }
    else {
      String whereString = "parcours = '$parcours'";
      result = await db.query(tableEquipes, orderBy: orderBy, where: whereString);
    }
    List<Equipes> r = result.map((e) => Equipes.fromJson(e)).toList();
    return r;
  }
  
  Future<Map<String, int>> countEquipes() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT parcours, COUNT(*) as count
      FROM $tableEquipes
      GROUP BY parcours
    ''');

    final List<String> list_parcours = await getParcours();

    final Map<String, int> r = {
      for (var p in list_parcours) p:0
    };

    for (var row in result) {
      final parcours = row["parcours"] as String?;
      final count = row["count"] as int?;
      if (parcours != null && count != null) {
        r[parcours] = count;
      }
    }
    return r;
  }

  /// Balise

  Future<String> createBalise(Balise b) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT *
      FROM $tableBalise
      WHERE ${BaliseField.dossard} = ${b.dossard}
    ''');
    if (result.isNotEmpty) {
      return result.first['nb_balise'].toString();
    }
    else {
      final json = b.toJson();
      await db.insert(tableBalise, json);
      return '';
    }
  }

  Future<Balise?> getBalise(String dossard) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT *
      FROM $tableBalise
      WHERE ${BaliseField.dossard} = '$dossard'
    ''');
    if (result.isNotEmpty) {
      Balise r = Balise.fromJson(result[0]);
      return r;
    }
    return null;
  }

  Future<List<Balise>> getBalises() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT *
      FROM $tableBalise
      ORDER BY ${BaliseField.dossard} ASC
    ''');
    List<Balise> r = result.map((e) => Balise.fromJson(e)).toList();
    return r;
  }

  Future editBalise(String dossard, String nb_balise) async {
    final db = await instance.database;
    await db.rawQuery('''
      UPDATE $tableBalise
      SET ${BaliseField.nb_balise} = '$nb_balise'
      WHERE ${BaliseField.dossard} = '$dossard'
    ''');
  }

  /// Temps

  Future<void> createTemps(Temps t) async {
    final nb_epreuves = ((await readJsonEpreuves(t.ravito))[t.parcours]!).length;
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as c
      FROM $tableTemps
      WHERE ${TempsField.dossard} = '${t.dossard}' AND ${TempsField.ravito} = '${t.ravito}' AND ${TempsField.status} = TRUE
    ''');
    final int nb_temps = result[0]['c'] as int;
    if (nb_temps >= nb_epreuves) {
      throw Exception('Erreur : Nombre maximum de temps atteint');
    }
    final json = t.toJson();
    await db.insert(tableTemps, json);
    final a = Action(ActionType.DepartSimple, t.ravito, DateTime.now().toIso8601String(), t.id, t.parcours, t.dossard.toString(), '-', t.date).toJson();
    await db.insert(tableAction, a);
    getTemps();
  }

  Future<void> createTempsGroupe(String parcours, String date, String ravito) async {
    final nb_epreuves = ((await readJsonEpreuves(ravito))[parcours]!).length;
    final dossards = (await getEquipes(parcours)).map((equ) => equ.dossard).toList();
    final db = await instance.database;

    int nb_temps_ref = -1;

    for (var d in dossards) {
      final nb_temps = (await db.rawQuery('''
        SELECT COUNT(*) as c
        FROM $tableTemps
        WHERE ${TempsField.dossard} = '$d' AND ${TempsField.status} = TRUE
      '''))[0]['c'] as int;
      if (nb_temps_ref == -1) {
        nb_temps_ref = nb_temps;
      } else if (nb_temps != nb_temps_ref){
        throw Exception('Erreur : lignes remplies inégalement');
      }
    }
    if (nb_temps_ref >= nb_epreuves) {
      throw Exception('Erreur : lignes pleines');
    }
    String temps_ids = "";
    final String now = DateTime.now().toIso8601String();
    for (var d in dossards) {
      final t = Temps(d, date, parcours, ravito, true, now);
      final json = t.toJson();
      await db.insert(tableTemps, json);
      temps_ids += '${t.id}/';
    }
    final a = Action(ActionType.DepartGroupe, ravito, DateTime.now().toIso8601String(), temps_ids, parcours, '-', '-', date).toJson();
    await db.insert(tableAction, a);
  }

  Future editTemps(Temps t, String date) async {
    final String now = DateTime.now().toIso8601String();
    final db = await instance.database;
    final a = Action(ActionType.Edit, t.ravito, now, t.id, t.parcours, t.dossard.toString(), t.date, date).toJson();
    await db.insert(tableAction, a);
    await db.execute('''
      UPDATE $tableTemps
      SET ${TempsField.date} = '$date', ${TempsField.last_modification_date} = '$now'
      WHERE ${TempsField.id} = '${t.id}'
    ''');
  }

  Future deleteTemps(Temps t) async {
    final String now = DateTime.now().toIso8601String();
    final db = await instance.database;
    await db.execute('''
      UPDATE $tableTemps
      SET ${TempsField.status} = FALSE, ${TempsField.last_modification_date} = '$now'
      WHERE ${TempsField.id} = '${t.id}'
    ''');
    final a = Action(ActionType.Delete, t.ravito, DateTime.now().toIso8601String(), t.id, t.parcours, t.dossard.toString(), t.date, '-').toJson();
    await db.insert(tableAction, a);
    
  }

  Future<List<Temps>> getTemps() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT *
      FROM $tableTemps
      WHERE ${TempsField.status} = TRUE
      ORDER BY ${TempsField.dossard} ASC
    ''');
    List<Temps> r = result.map((e) => Temps.fromJson(e)).toList();
    return r;
  }
  
  /// Synchonisation

  Future<List<Temps>> getTempsSince(String limite_date) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT *
      FROM $tableTemps
      WHERE ${TempsField.last_modification_date} > '$limite_date'
      ORDER BY ${TempsField.dossard} ASC
    ''');
    List<Temps> r = result.map((e) => Temps.fromJson(e)).toList();
    return r;
  }

    Future<void> deleteTempsSince(String limite_date) async {
    final db = await instance.database;
    await db.rawQuery('''
      DELETE FROM $tableTemps
      WHERE ${TempsField.last_modification_date} > '$limite_date'
    ''');
  }
  
  Future<void> addListTemps(List<Temps> list_temps) async {
    final db = await instance.database;
    for (var t in list_temps) {
    final json = t.toJson();
      await db.insert(tableTemps, json);
    }
  }

  /// Action

  Future<List<Action>> getAction(String ravito) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT *
      FROM $tableAction
      WHERE ${ActionField.ravito} = '$ravito'
      ORDER BY ${ActionField.date} DESC;
    ''');
    List<Action> r = result.map((e) => Action.fromJson(e)).toList();
    return r;
  }

  Future annuleDerniereAction(String ravito) async {
    final String now = DateTime.now().toIso8601String();
    final db = await instance.database;
    final result = (await db.rawQuery('''
      SELECT *
      FROM $tableAction
      WHERE ${ActionField.ravito} = '$ravito'
      ORDER BY ${ActionField.date} DESC
      LIMIT 1
    '''))[0];

    final action = Action.fromJson(result);

    switch(action.type) {
      case ActionType.DepartSimple:
        await db.execute('''
          UPDATE $tableTemps
          SET ${TempsField.status} = FALSE, ${TempsField.last_modification_date} = '$now'
          WHERE ${TempsField.id} = '${action.temps_id}'
        ''');
        break;
      
      case ActionType.DepartGroupe:
        final List ids = action.temps_id.split('/');
        final String string_id = "(${ids.map((e) => "'$e'").join(',')})";
        await db.execute('''
          UPDATE $tableTemps
          SET ${TempsField.status} = FALSE, ${TempsField.last_modification_date} = '$now'
          WHERE ${TempsField.id} IN $string_id
        ''');

      case ActionType.Delete:
        await db.execute('''
          UPDATE $tableTemps
          SET ${TempsField.status} = TRUE, ${TempsField.last_modification_date} = '$now'
          WHERE ${TempsField.id} = '${action.temps_id}'
        ''');
        
      case ActionType.Edit:
        await db.execute('''
          UPDATE $tableTemps
          SET ${TempsField.date} = '${action.ancien_temps}', ${TempsField.last_modification_date} = '$now'
          WHERE ${TempsField.id} = '${action.temps_id}'
        ''');

      case ActionType.Default:
        throw Exception('Action non définie');
    }
    await db.execute('''
      DELETE FROM $tableAction
      WHERE ${ActionField.id} = '${action.id}'
    ''');
  }

  /// Specific cruds

  Future<List<Temps>> getTempsbyDossard(String dossard, String ravito) async {
    final db = await instance.database;
    
    final result;
    if (ravito != 'admin') {
      result = await db.rawQuery('''
        SELECT *
        FROM $tableTemps
        WHERE ${TempsField.ravito} = '$ravito' AND ${TempsField.dossard} = '$dossard' AND ${TempsField.status} = TRUE
        ORDER BY ${TempsField.date} ASC;
      ''');
    } else {
      result = await db.rawQuery('''
        SELECT *
        FROM $tableTemps
        WHERE ${TempsField.dossard} = '$dossard' AND ${TempsField.status} = TRUE
        ORDER BY ${TempsField.date} ASC;
      ''');
    }
    final r = List<Temps>.from(result.map((e) => Temps.fromJson(e)));
    
    return r;
  }

  Future<Map<String, Map<int, List<String>>>> getTempsOrderedbyDossard(String ravito) async {
    final db = await instance.database;
    final result;
    if (ravito != 'admin') {
      result = await db.rawQuery('''
        SELECT ${TempsField.parcours}, ${TempsField.dossard}, ${TempsField.date}
        FROM $tableTemps
        WHERE ${TempsField.ravito} = '$ravito' AND ${TempsField.status} = TRUE
        ORDER BY ${TempsField.parcours} ASC, ${TempsField.dossard} ASC, ${TempsField.date} ASC
      ''');
    } else {
      result = await db.rawQuery('''
        SELECT ${TempsField.parcours}, ${TempsField.dossard}, ${TempsField.date}
        FROM $tableTemps
        WHERE ${TempsField.status} = TRUE
        ORDER BY ${TempsField.parcours} ASC, ${TempsField.dossard} ASC, ${TempsField.date} ASC
      ''');
    }
    final Map<String, Map<int, List<String>>> data = {};

    for (var row in result) {
      final String parcours = row[TempsField.parcours] as String;
      final int dossard = row[TempsField.dossard] as int;
      final String date = row[TempsField.date] as String;
      data.putIfAbsent(parcours, () => {});
      data[parcours]!.putIfAbsent(dossard, () => []);
      data[parcours]![dossard]!.add(date);
    }
    return data;
  }

  Future<Map<String,Map<String,int>>> compteTemps(String ravito) async {
    final epreuves = await readJsonEpreuves(ravito);
    final c = await countEquipes();
    final List<String> list_parcours = await getParcours();
    Map<String,Map<String,int>> data = {for (var parcours in list_parcours) parcours : {for (var epreuve in (epreuves[parcours]!)) epreuve : (epreuve==epreuves[parcours]![0] ? c[parcours]! : 0) }};
    final db = await instance.database;
    final result;

    if (ravito != 'admin') {
      result = await db.rawQuery('''
        SELECT ${TempsField.parcours}, time_count, COUNT(*) as dossard_count
        FROM (
          SELECT ${TempsField.parcours}, ${TempsField.dossard}, COUNT(*) as time_count
          FROM $tableTemps
          WHERE ${TempsField.ravito} = '$ravito' AND ${TempsField.status} = TRUE
          GROUP BY ${TempsField.parcours}, ${TempsField.dossard}
        ) AS counts
        GROUP BY ${TempsField.parcours}, time_count
        ORDER BY ${TempsField.parcours} ASC, time_count ASC
      ''');
    } else {
      result = await db.rawQuery('''
        SELECT ${TempsField.parcours}, time_count, COUNT(*) as dossard_count
        FROM (
          SELECT ${TempsField.parcours}, ${TempsField.dossard}, COUNT(*) as time_count
          FROM $tableTemps
          WHERE ${TempsField.status} = TRUE
          GROUP BY ${TempsField.parcours}, ${TempsField.dossard}
        ) AS counts
        GROUP BY ${TempsField.parcours}, time_count
        ORDER BY ${TempsField.parcours} ASC, time_count ASC
      ''');
    }

    final counts = result.map((row) => {
      'parcours': row['parcours'].toString(),
      'time_count': row['time_count'].toString(),
      'dossard_count': row['dossard_count'].toString(),
    }).toList();

    for (var count in counts) {
      final parcours = count["parcours"]!;
      final timeCount = int.parse(count["time_count"]!);
      final dossardCount = int.parse(count["dossard_count"]!);
      final firstEpreuve = epreuves[parcours]![0];

      if (timeCount < epreuves[parcours]!.length) {
        final currentEpreuve = epreuves[parcours]![timeCount];
        data[parcours]![currentEpreuve] =
            (data[parcours]![currentEpreuve] ?? 0) + dossardCount;
      }

      data[parcours]![firstEpreuve] =
          (data[parcours]![firstEpreuve] ?? 0) - dossardCount;
    }
    return data;
  }

  Future<List<int>> compteDossard(String parcours, String epreuve, String ravito) async {
    final db = await instance.database;
    final epreuves = (await readJsonEpreuves(ravito))[parcours] as List<String>;
    final targetTimeCount = epreuves.indexOf(epreuve);

    if (targetTimeCount == 0) {
      final equipes = (await getEquipes(parcours)).map((eq) => eq.dossard);

      final result;
      if (ravito != 'admin') {
        result = await db.rawQuery('''
          SELECT DISTINCT ${TempsField.dossard}
          FROM $tableTemps
          WHERE ${TempsField.parcours} = '$parcours' AND ${TempsField.ravito} = '$ravito' AND ${TempsField.status} = TRUE
        ''');
      } else {
        result = await db.rawQuery('''
          SELECT DISTINCT ${TempsField.dossard}
          FROM $tableTemps
          WHERE ${TempsField.parcours} = '$parcours' AND ${TempsField.status} = TRUE
        ''');
      }

      final dossardsAvecTemps = result.map((row) => row[TempsField.dossard] as int).toSet();
      return equipes.where((dossard) => !dossardsAvecTemps.contains(dossard)).toList();

    } else {
      final result;
      if (ravito != 'admin') {
        result = await db.rawQuery('''
          SELECT ${TempsField.dossard}, COUNT(*) as time_count
          FROM $tableTemps
          WHERE ${TempsField.parcours} = '$parcours' AND ${TempsField.ravito} = '$ravito' AND ${TempsField.status} = TRUE
          GROUP BY ${TempsField.dossard}
          HAVING time_count = $targetTimeCount
        ''');
      } else {
        result = await db.rawQuery('''
          SELECT ${TempsField.dossard}, COUNT(*) as time_count
          FROM $tableTemps
          WHERE ${TempsField.parcours} = '$parcours' AND ${TempsField.status} = TRUE
          GROUP BY ${TempsField.dossard}
          HAVING time_count = $targetTimeCount
        ''');
      }

      return result.map<int>((row) => row[TempsField.dossard] as int).toList();
    }
  }

  Future<Map<String,List<Map<String, String>>>> compteTempsManquants() async { 
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        ${TempsField.dossard} AS dossard, 
        ${TempsField.ravito} AS ravito, 
        COUNT(*) AS time_count, 
        ${TempsField.parcours} AS parcours
      FROM $tableTemps
      WHERE ${TempsField.status} = TRUE
      GROUP BY ${TempsField.dossard}, ${TempsField.ravito}, ${TempsField.parcours};
    ''');

    Map<String, Map<int, Map<String, int>>> data = {};

    for (var row in result) {
      final int dossard = row['dossard'] as int;
      final String ravito = row['ravito'] as String;
      final int timeCount = row['time_count'] as int;
      final String parcours = row['parcours'] as String;
      data.putIfAbsent(parcours, () => {});
      data[parcours]!.putIfAbsent(dossard, () => {});
      data[parcours]![dossard]![ravito] = timeCount;
    }

    final nb_epr = await compteEpreuves();
    final List<String> list_parcours = await getParcours();
    Map<String,List<Map<String, String>>> temps_manquants = {for (var parcours in list_parcours) parcours: []};

    for (var p in data.keys) {
      for (var d in data[p]!.entries) {
        int i = 2;
        int nb = 0;
        for (var e_i in List.generate(nb_epr[p]!.entries.length, (i) => i)) {
          dynamic e = nb_epr[p]!.entries.toList()[e_i];
          d.value[e.key] ??= 0;
          if (d.value[e.key] == 0) {
            i = 0;
          } else if (e.value == d.value[e.key]) {
            if (i != 2) {
              temps_manquants[p]!.add({
                'dossard': d.key.toString(),
                'ravito': nb_epr[p]!.keys.toList()[e_i-1],
                'nb': nb.toString()
              });
            }
            i = 2;
          } else if (e.value > d.value[e.key]) {
            if (i != 2) {
              temps_manquants[p]!.add({
                'dossard': d.key.toString(),
                'ravito': nb_epr[p]!.keys.toList()[e_i-1],
                'nb': nb.toString()
              });            }
            i = 1;
          }
          nb = e.value - d.value[e.key];
        }
      }
    }

    return temps_manquants;
  }

  /// Remarque

  Future createRemarque(Remarque r) async {
    final db = await instance.database;
    final json = r.toJson();
    await db.insert(tableRemarque, json);
  }
  
  Future<List<Remarque>> getRemarque(String ravito) async {
    final db = await instance.database;
    final result;
    if (ravito != 'admin') {
      result = await db.rawQuery('''
        SELECT *
        FROM $tableRemarque
        WHERE ${RemarqueField.ravito} = '$ravito'
        ORDER BY ${RemarqueField.date} ASC
      ''');
    } else {
      result = await db.rawQuery('''
        SELECT *
        FROM $tableRemarque
        ORDER BY ${RemarqueField.date} ASC
      ''');
    }
    List<Remarque> r = result.map<Remarque>((e) => Remarque.fromJson(e)).toList();
    return r;
  }


}
