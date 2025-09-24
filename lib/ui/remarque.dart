import 'package:uuid/uuid.dart';

const String tableRemarque = "remarque";

class RemarqueField {
  static final List<String> values = [
    id,
    date,
    ravito,
    text,
  ];

  // Le nom des colonnes dans la base de donnée
  static const String id = "id";
  static const String date = "date";
  static const String ravito = "ravito";
  static const String text = "text";
}

class Remarque {
  String id = "";
  String date = "";
  String ravito = "";
  String text = "";

  Remarque(String Date, String Ravito, String Text, {String Id = ""}) {
    id = Id.isEmpty ? Uuid().v4() : Id;
    date = Date;
    ravito = Ravito;
    text = Text;
  }
  
  @override
  String toString(){
    return "Remarque(id: $id, date: $date, ravito: $ravito, text: $text)";
  }

  static Remarque fromJson(Map<String, Object?> json) =>
    Remarque(
        json[RemarqueField.date] as String,
        json[RemarqueField.ravito] as String,
        json[RemarqueField.text] as String,
        Id: json[RemarqueField.id] as String,
      );

  Map<String, Object> toJson() =>
    {
      RemarqueField.id: id,
      RemarqueField.date: date,
      RemarqueField.ravito: ravito,
      RemarqueField.text: text,
    };

}