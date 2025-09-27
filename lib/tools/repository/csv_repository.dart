import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:chrono_raid/tools/exception.dart';
import 'package:chrono_raid/tools/repository/repository.dart';

class CsvRepository extends Repository {
  static const String expiredTokenDetail = "Could not validate credentials";

  Future<String> getCsv({String suffix = ""}) async {
    try {
      final response = await http
          .get(Uri.parse("${Repository.host}$ext$suffix"), headers: headers);
      if (response.statusCode == 200) {
        try {
          return response.body;
        } catch (e) {
          rethrow;
        }
      } else if (response.statusCode == 403) {
        String resp = utf8.decode(response.body.runes.toList());
        final decoded = json.decode(resp);
        if (decoded["detail"] == expiredTokenDetail) {
          throw AppException(ErrorType.tokenExpire, decoded["detail"]);
        } else {
          throw AppException(ErrorType.notFound, decoded["detail"]);
        }
      } else {
        throw AppException(ErrorType.notFound, response.body);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
