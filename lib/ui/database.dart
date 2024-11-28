import 'package:chrono_raid/ui/functions.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/v4.dart';

import 'temps.dart';
import 'equipes.dart';

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

    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableTemps (
        ${TempsField.id} $stringType,
        ${TempsField.dossard} $intType,
        ${TempsField.date} $stringType,
        ${TempsField.parcours} $stringType
    );
    ''');
  }

  Future createTableEquipes() async {
    final db = await instance.database;
    await db.delete(tableEquipes);
    final value = await readJsonEquipes();
    final List<Map<String,String>> equipes = value;
    for (int i=0; i<equipes.length; i++) {
      final Map<String,String> json = equipes[i];
      await db.insert(tableEquipes, json); 
    }
  }

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

  final Map<String, int> r = {
    "Expert": 0,
    "Sportif": 0,
    "Découverte": 0,
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

  Future<String> createTemps(Temps t) async {
    final nb_epreuves = ((await readJsonEpreuves())[t.parcours]!).length;
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as c
      FROM $tableTemps
      WHERE dossard = ${t.dossard}
    ''');
    final int nb_temps = result[0]['c'] as int;
    if (nb_temps >= nb_epreuves) {
      return 'error'; //provisoire
    }
    else {
      final json = t.toJson();
      await db.insert(tableTemps, json);
      return ''; //provisoire
    }
  }

  Future editTemps(Temps t, String date) async {
    final db = await instance.database;
    await db.execute('''
      UPDATE $tableTemps
      SET ${TempsField.date} = '$date'
      WHERE ${TempsField.id} = '${t.id}'
    ''');
  }

  Future<List<Temps>> getTemps() async {
    final db = await instance.database;
    const orderBy = '${TempsField.dossard} ASC';
    final result = await db.query(tableTemps, orderBy: orderBy);
    List<Temps> r = result.map((e) => Temps.fromJson(e)).toList();
    return r;
  }

  Future<List<Temps>> getTempsbyDossard(dossard) async {
    final db = await instance.database;
    const orderBy = '${TempsField.date} ASC';
    String whereString = "dossard = '$dossard'";
    final result = await db.query(tableTemps, orderBy: orderBy, where: whereString);
    List<Temps> r = result.map((e) => Temps.fromJson(e)).toList();
    return r;
  }

  Future<Map<String, Map<int, List<String>>>> getTempsOrderedbyDossard() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT ${TempsField.parcours}, ${TempsField.dossard}, ${TempsField.date}
      FROM $tableTemps
      ORDER BY ${TempsField.parcours} ASC, ${TempsField.dossard} ASC, ${TempsField.date} ASC
    ''');
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

  Future<Map<String,Map<String,int>>> compteTemps() async {
    final epreuves = await readJsonEpreuves();
    final c = await countEquipes();
    Map<String,Map<String,int>> data = {for (var parcours in ["Expert", "Sportif", "Découverte"]) parcours : {for (var epreuve in (epreuves[parcours]!)) epreuve : (epreuve==epreuves[parcours]![0] ? c[parcours]! : 0) }};
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT ${TempsField.parcours}, time_count, COUNT(*) as dossard_count
      FROM (
        SELECT ${TempsField.parcours}, ${TempsField.dossard}, COUNT(*) as time_count
        FROM $tableTemps
        GROUP BY ${TempsField.parcours}, ${TempsField.dossard}
      ) AS counts
      GROUP BY ${TempsField.parcours}, time_count
      ORDER BY ${TempsField.parcours} ASC, time_count ASC
    ''');

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

}
