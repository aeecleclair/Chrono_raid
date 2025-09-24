import 'package:uuid/uuid.dart';

const String tableTemps = "temps";

class TempsField {
  static final List<String> values = [
    id,
    dossard,
    date,
    parcours,
    ravito,
    status,
    last_modification_date,
  ];

  // Le nom des colonnes dans la base de donnée
  static const String id = "id";
  static const String dossard = "dossard";
  static const String date = "date";
  static const String parcours = "parcours";
  static const String ravito = "ravito";
  static const String status = "status";
  static const String last_modification_date = "last_modification_date";
}

class Temps {
  String id = "";
  int dossard = 0;
  String date = "";
  String parcours = "";
  String ravito = "";
  bool status = true;
  String last_modification_date = "";

  Temps(
    int Dossard,
    String Date,
    String Parcours,
    String Ravito,
    bool status,
    String Last_modification_date,
    {String Id = ""}
  ) {
    id = Id.isEmpty ? Uuid().v4() : Id;
    dossard = Dossard;
    date = Date;
    parcours = Parcours;
    ravito = Ravito;
    status = status;
    last_modification_date = Last_modification_date;
  }

  @override
  String toString(){
    return "Temps(id: $id, dossard: $dossard, parcours: $parcours, ravito: $ravito, date: $date, status: $status, last modification date: $last_modification_date)";
  }

  static Temps fromJson(Map<String, Object?> json) =>
    Temps(
        json[TempsField.dossard] as int,
        json[TempsField.date] as String,
        json[TempsField.parcours] as String,
        json[TempsField.ravito] as String,
        json[TempsField.status] == 1,
        json[TempsField.last_modification_date] as String,
        Id: json[TempsField.id] as String,
      );

  Map<String, Object> toJson() =>
    {
      TempsField.id: id,
      TempsField.dossard: dossard,
      TempsField.date: date,
      TempsField.parcours: parcours,
      TempsField.ravito: ravito,
      TempsField.status: status ? 1 : 0,
      TempsField.last_modification_date: last_modification_date,
    };

}