const String tableEquipes = "equipes";

class EquipesField {
  static final List<String> values = [
    dossard,
    parcours,
  ];

  // Le nom des colonnes dans la base de donnée
  static const String dossard = "dossard";
  static const String parcours = "parcours";
}

class Equipes {
  int dossard = 0;
  String parcours = "";


  Equipes(int Dossard, String Parcours) {
    dossard = Dossard;
    parcours = Parcours;
  }

  static Equipes fromJson(Map<String, Object?> json) =>
    Equipes(
        json[EquipesField.dossard] as int,
        json[EquipesField.parcours] as String,
      );

  Map<String, Object> toJson() =>
    {
      EquipesField.dossard: dossard,
      EquipesField.parcours: parcours,
    };

}