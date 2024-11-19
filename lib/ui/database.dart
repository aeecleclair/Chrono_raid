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
    //await deleteDatabase(path);
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

  Future createTemps(Temps t) async {
    final db = await instance.database;
    final json = t.toJson();
    await db.insert(tableTemps, json); 
  }

  Future<List<Temps>> getTemps() async {
    final db = await instance.database;
    const orderBy = '${TempsField.dossard} ASC';
    final result = await db.query(tableTemps, orderBy: orderBy);
    List<Temps> r = result.map((e) => Temps.fromJson(e)).toList();
    return r;
  }

}
