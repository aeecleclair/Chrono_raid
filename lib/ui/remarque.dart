import 'package:uuid/uuid.dart';

const String tableRemarque = "remarque";

class RemarqueField {
  static final List<String> values = [
    id,
    date,
    ravito,
    texte,
  ];

  // Le nom des colonnes dans la base de donnée
  static const String id = "id";
  static const String date = "date";
  static const String ravito = "ravito";
  static const String texte = "texte";
}

class Remarque {
  String id = "";
  String date = "";
  String ravito = "";
  String texte = "";

  Remarque(String Date, String Ravito, String Texte, {String Id = ""}) {
    id = Id.isEmpty ? Uuid().v4() : Id;
    date = Date;
    ravito = Ravito;
    texte = Texte;
  }
  
  @override
  String toString(){
    return "Remarque(id: $id, date: $date, ravito: $ravito, texte: $texte)";
  }

  static Remarque fromJson(Map<String, Object?> json) =>
    Remarque(
        json[RemarqueField.date] as String,
        json[RemarqueField.ravito] as String,
        json[RemarqueField.texte] as String,
        Id: json[RemarqueField.id] as String,
      );

  Map<String, Object> toJson() =>
    {
      RemarqueField.id: id,
      RemarqueField.date: date,
      RemarqueField.ravito: ravito,
      RemarqueField.texte: texte,
    };

}