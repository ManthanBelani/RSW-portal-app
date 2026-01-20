import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class ClientList {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final clientListApiUrl = '$baseUrl/utils/client_list.php';
  static final projectUserListApiUrl = '$baseUrl/utils/project_list_user.php';
  static final currencyListApiUrl = '$baseUrl/utils/currency_list.php';
  static final bankListApiUrl = '$baseUrl/utils/company_list.php';
  static final getClientDataApiUrl = '$baseUrl/invoice/get_client_data.php?value=';
  static final activeProposalListApiUrl =
      '$baseUrl/utils/active_proposal_list.php';


  static Future<Map<String, dynamic>?> getClientList() async {
    try {
      final response = await ApiClient.get(clientListApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Client list fetched successfully',
          'data': data['data'] ?? data,
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch client list'};
      }
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getProjectUserList() async {
    try {
      final response = await ApiClient.get(projectUserListApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'project user list fetched successfully',
          'data': data['data'] ?? data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch project user list',
        };
      }
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getCurrencyList() async {
    try {
      final response = await ApiClient.get(currencyListApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'currency list fetched successfully',
          'data': data['data'] ?? data,
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch currency list'};
      }
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getBankList() async {
    try {
      final response = await ApiClient.get(bankListApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Bank list fetched successfully',
          'data': data['data'] ?? data,
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch Bank list'};
      }
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getActiveProposalList() async {
    try {
      final response = await ApiClient.get(activeProposalListApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'ActiveProposal list fetched successfully',
          'data': data['data'] ?? data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch ActiveProposal list',
        };
      }
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getClientDataOnSelect(String clientId) async {
    try {
      final url = '$getClientDataApiUrl$clientId';
      print('Fetching client data from: $url');
      final response = await ApiClient.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Client data fetched: $data');
        return {
          'success': true,
          'message': 'Client data fetched successfully',
          'data': data['data'] ?? data, // Handle both formats
        };
      } else {
        print('❌ Failed to fetch client data: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to fetch client data',
        };
      }
    } on ApiException catch (e) {
      print('API Exception: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
