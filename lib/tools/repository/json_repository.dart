import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chrono_raid/tools/repository/repository.dart';
import 'package:chrono_raid/tools/exception.dart';

class JsonRepository extends Repository {
  /// Récupère un JSON depuis le backend et le stocke en cache
  Future<Map<String, dynamic>> getJson(String filename) async {
    final String suffix = "chrono_raid/json/$filename";

    try {
      final response = await http
          .get(Uri.parse("${Repository.host}$ext$suffix"), headers: headers);

      if (response.statusCode == 200) {
        try {
          String toDecode = utf8.decode(response.bodyBytes);
          final decoded = jsonDecode(toDecode);
          final jsonContent = decoded["content"] ?? {};

          return jsonContent as Map<String, dynamic>;
        } catch (e) {
          return <String, dynamic>{};
        }
      } else if (response.statusCode == 403) {
        try {
          String toDecode = utf8.decode(response.body.runes.toList());
          final decoded = jsonDecode(toDecode);
          if (decoded["detail"] == Repository.expiredTokenDetail) {
            throw AppException(ErrorType.tokenExpire, decoded["detail"]);
          } else {
            throw AppException(ErrorType.notFound, decoded["detail"]);
          }
        } on AppException {
          rethrow;
        } catch (e) {
          throw AppException(ErrorType.notFound, response.body);
        }
      } else {
        throw AppException(ErrorType.notFound, response.body);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      return <String, dynamic>{};
    }
  }
}
