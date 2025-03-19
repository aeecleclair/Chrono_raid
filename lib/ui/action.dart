import 'package:chrono_raid/ui/functions.dart';
import 'package:uuid/uuid.dart';

const String tableAction = "action";

class ActionField {
  static final List<String> values = [
    id,
    type,
    ravito,
    date,
    temps_id,
    parcours,
    dossard,
    ancien_temps,
    nouveau_temps,
  ];

  // Le nom des colonnes dans la base de donnée
  static const String id = "id";
  static String type = "type";
  static const String ravito = "ravito";
  static const String date = "date";
  static const String temps_id = "temps_id";
  static const String parcours = "parcours";
  static const String dossard = "dossard";
  static const String ancien_temps = "ancien_temps";
  static const String nouveau_temps = "nouveau_temps";

}

class Action {
  String id = "";
  ActionType type = ActionType.Default;
  String ravito = "";
  String date = "";
  String temps_id = "";
  String parcours = "";
  String dossard = "";
  String ancien_temps = "";
  String nouveau_temps = "";

  Action(ActionType Type, String Ravito, String Date, String Temps_id, String Parcours, String Dossard, String AncienTemps, String NouveauTemps, {String Id = ""}) {
    id = Id.isEmpty ? Uuid().v4() : Id;
    type = Type;
    ravito = Ravito;
    date = Date;
    temps_id = Temps_id;
    parcours = Parcours;
    dossard = Dossard;
    ancien_temps = AncienTemps;
    nouveau_temps = NouveauTemps;
  }
  
  @override
  String toString(){
    return "Action(id: $id, type: $type, ravito: $ravito, date: $date, temps_id: $temps_id, parcours: $parcours, dossard: $dossard, temps: $ancien_temps, temps_json: $nouveau_temps)";
  }

  static Action fromJson(Map<String, Object?> json) =>
    Action(
        stringToActionType(json[ActionField.type] as String),
        json[ActionField.ravito] as String,
        json[ActionField.date] as String,
        json[ActionField.temps_id] as String,
        json[ActionField.parcours] as String,
        json[ActionField.dossard] as String,
        json[ActionField.ancien_temps] as String,
        json[ActionField.nouveau_temps] as String,
        Id: json[ActionField.id] as String,
      );

  Map<String, Object> toJson() =>
    {
      ActionField.id: id,
      ActionField.type: actionTypeToString(type),
      ActionField.ravito: ravito,
      ActionField.date: date,
      ActionField.temps_id: temps_id,
      ActionField.parcours:parcours,
      ActionField.dossard:dossard,
      ActionField.ancien_temps:ancien_temps,
      ActionField.nouveau_temps:nouveau_temps,
    };

}