import 'package:uuid/uuid.dart';

const String tableRemarque = "remarque";

class RemarqueField {
  static final List<String> values = [
    id,
    date,
    texte,
  ];

  // Le nom des colonnes dans la base de donnée
  static const String id = "id";
  static const String date = "date";
  static const String texte = "texte";

}

class Remarque {
  String id = "";
  String date = "";
  String texte = "";

  Remarque(String Date, String Texte, {String Id = ""}) {
    id = Id.isEmpty ? Uuid().v4() : Id;
    date = Date;
    texte = Texte;
  }
  
  @override
  String toString(){
    return "Remarque(id: $id, date: $date, texte: $texte)";
  }

  static Remarque fromJson(Map<String, Object?> json) =>
    Remarque(
        json[RemarqueField.date] as String,
        json[RemarqueField.texte] as String,
        Id: json[RemarqueField.id] as String,
      );

  Map<String, Object> toJson() =>
    {
      RemarqueField.id: id,
      RemarqueField.date: date,
      RemarqueField.texte: texte,
    };

}