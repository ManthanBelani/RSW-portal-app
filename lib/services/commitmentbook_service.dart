import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_client.dart';

class CommitmentbookService {
  final baseUrl = dotenv.env['BASE_URL'];
  late final viewRuleBookApiUrl = '$baseUrl/rulebook/view_rulebook.php?id=1';

  String _viewRuleBookDataApiUrl({required int id}) {
    String url = '$viewRuleBookApiUrl?id=$id';
    return url;
  }

  Future<Map<String, dynamic>?> getCommitmentBookDetails({int id = 0}) async {
    try {
      final url = _viewRuleBookDataApiUrl(id: id);

      print('=== CommitmentBook Service ===');
      print('Making authenticated request to: $url');

      final response = await ApiClient.get(url);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! CommitmentBook data retrieved');
        print('Response Data: $responseData');
        return responseData;
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error body: ${response.body}');
        return null;
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {
        'success': false,
        'error': {'code': e.errorCode ?? 'UNKNOWN', 'message': e.message},
      };
    } catch (e, stackTrace) {
      print('Exception in getNotesList: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}
