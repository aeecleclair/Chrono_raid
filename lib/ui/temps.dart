import 'package:uuid/uuid.dart';

const String tableTemps = "temps";

class TempsField {
  static final List<String> values = [
    id,
    dossard,
    date,
    parcours,
    ravito,
  ];

  // Le nom des colonnes dans la base de donnée
  static const String id = "id";
  static const String dossard = "dossard";
  static const String date = "date";
  static const String parcours = "parcours";
  static const String ravito = "ravito";
}

class Temps {
  String id = "";
  int dossard = 0;
  String date = "";
  String parcours = "";
  String ravito = "";

  Temps(int Dossard, String Date, String Parcours, String Ravito, {String Id = ""}) {
    id = Id.isEmpty ? Uuid().v4() : Id;
    dossard = Dossard;
    date = Date;
    parcours = Parcours;
    ravito = Ravito;
  }

  @override
  String toString(){
    return "Temps(id: $id, dossard: $dossard, parcours: $parcours, ravito: $ravito, date: $date)";
  }

  static Temps fromJson(Map<String, Object?> json) =>
    Temps(
        json[TempsField.dossard] as int,
        json[TempsField.date] as String,
        json[TempsField.parcours] as String,
        json[TempsField.ravito] as String,
        Id: json[TempsField.id] as String,
      );

  Map<String, Object> toJson() =>
    {
      TempsField.id: id,
      TempsField.dossard: dossard,
      TempsField.date: date,
      TempsField.parcours:parcours,
      TempsField.ravito:ravito,
    };

}