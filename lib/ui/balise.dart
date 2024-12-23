const String tableBalise = "balise";

class BaliseField {
  static final List<String> values = [
    dossard,
    nb_balise,
  ];

  // Le nom des colonnes dans la base de donnée
  static const String dossard = "dossard";
  static const String nb_balise = "nb_balise";
}

class Balise {
  int dossard = 0;
  int nb_balise = 0;

  Balise(int Dossard, int NB_balise) {
    dossard = Dossard;
    nb_balise = NB_balise;
  }
  
  @override
  String toString(){
    return "Balise(dossard: $dossard, nb_balise: $nb_balise)";
  }

  static Balise fromJson(Map<String, Object?> json) =>
    Balise(
        json[BaliseField.dossard] as int,
        json[BaliseField.nb_balise] as int,
      );

  Map<String, Object> toJson() =>
    {
      BaliseField.dossard: dossard,
      BaliseField.nb_balise: nb_balise,
    };

}