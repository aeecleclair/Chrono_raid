import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class JsonFolderStorage {
  final String folderName;

  JsonFolderStorage(this.folderName);

  // Récupérer le dossier (et le créer si besoin)
  Future<Directory> _getLocalDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/$folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Obtenir un fichier à partir de son nom
  Future<File> _getFile(String filename) async {
    final dir = await _getLocalDir();
    return File('${dir.path}/$filename.json');
  }

  /// Vérifie si un fichier JSON existe
  Future<bool> jsonExists(String filename) async {
    final dir = await _getLocalDir();
    return File('${dir.path}/$filename.json').exists();
  }

  // Sauvegarder un JSON avec un nom donné
  Future<void> writeJson(String filename, Map<String, dynamic> data) async {
    final file = await _getFile(filename);
    await file.writeAsString(jsonEncode(data));
  }

  // Lire un JSON
  Future<String> readJson(String filename) async {
    final file = await _getFile(filename);
    if (!await file.exists()) return '';
    return await file.readAsString();
  }

  // Lister tous les fichiers JSON du dossier
  Future<List<String>> listJsonFiles() async {
    final dir = await _getLocalDir();
    final files = dir.listSync().whereType<File>();
    return files.map((f) => f.path.split('/').last).toList();
  }

  // Supprimer un fichier JSON
  Future<bool> deleteJson(String filename) async {
    final file = await _getFile(filename);
    if (await file.exists()) {
      await file.delete();
      return true; // supprimé
    }
    return false; // fichier introuvable
  }

  /// Vérifie si le contenu a changé par rapport au fichier existant.
  Future<bool> isContentChanged(
      String filename, Map<String, dynamic> newContent) async {
    final file = await _getFile(filename);
    if (!(await file.exists())) {
      return true;
    }

    try {
      final existing = await file.readAsString();
      final existingJson = jsonDecode(existing);

      return !const DeepCollectionEquality().equals(existingJson, newContent);
    } catch (_) {
      return true;
    }
  }
}

void json_initialisation() async {
  final storage = JsonFolderStorage('json_data');
  if (!await storage.jsonExists('Epreuves') ||
      await storage.readJson('Epreuves') == '{}') {
    print('Remise à défault des json');
    await storage.writeJson('Epreuves', {
      'Default': {
        "Epreuves": {
          "Parcours": ["départ 1", "Arrivée 1"]
        }
      }
    });
  }
  if (!await storage.jsonExists('Equipes') ||
      await storage.readJson('Equipes') == '{}') {
    await storage.writeJson('Equipes', {
      "Equipes": [
        {"dossard": "0", "parcours": "Parcours"}
      ]
    });
  }
}

Future<String> loadJsonEquipes() async {
  final storage = JsonFolderStorage('json_data');
  return await storage.readJson('Equipes');
}

Future<String> loadJsonEpreuves() async {
  final storage = JsonFolderStorage('json_data');
  return await storage.readJson('Epreuves');
}

Future<bool> jsonIsChanged(String filename, Map<String, dynamic> data) async {
  final storage = JsonFolderStorage('json_data');
  bool hasChanged = await storage.isContentChanged(filename, data);
  return hasChanged;
}

Future<void> replaceJson(String filename, Map<String, dynamic> data) async {
  final storage = JsonFolderStorage('json_data');
  storage.writeJson(filename, data);
}
