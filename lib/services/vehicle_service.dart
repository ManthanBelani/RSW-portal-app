import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class VehicleService {
  static String _getVehicleListUrl({
    String direction = 'asc',
    String column = '0',
    int perPage = 50,
    int pageCount = 1,
    String search = '',
  }) {
    final baseUrl = dotenv.env['BASE_URL'] ??
        'https://rainflowweb.com/demo/account-upgrade/api';
    String url =
        '$baseUrl/vehicle/list_vehicle.php?direction=$direction&column=$column&per_page=$perPage&page_count=$pageCount&search=$search';

    return url;
  }

  static Future<Map<String, dynamic>?> getVehicleList({
    String direction = 'asc',
    String column = '0',
    int perPage = 50,
    int pageCount = 1,
    String search = '',
  }) async {
    try {
      final url = _getVehicleListUrl(
        direction: direction,
        column: column,
        perPage: perPage,
        pageCount: pageCount,
        search: search,
      );

      print('=== Vehicle Service ===');
      print('Making authenticated request to: $url');

      final response = await ApiClient.get(url);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Vehicle data retrieved');
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
        'error': {
          'code': e.errorCode ?? 'UNKNOWN',
          'message': e.message,
        },
      };
    } catch (e, stackTrace) {
      print('Exception in getVehicleList: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> deleteVehicle({
    required String vehicleId,
  }) async {
    try {
      final baseUrl = dotenv.env['BASE_URL'] ??
          'https://rainflowweb.com/demo/account-upgrade/api';
      final url = '$baseUrl/vehicle/delete_vehicle.php';

      print('=== Vehicle Delete Service ===');
      print('Making authenticated request to: $url');
      print('Vehicle ID: $vehicleId');

      final response = await ApiClient.post(
        url,
        {'id': vehicleId},
        isFormData: true,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Vehicle deleted');
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
        'error': {
          'code': e.errorCode ?? 'UNKNOWN',
          'message': e.message,
        },
      };
    } catch (e, stackTrace) {
      print('Exception in deleteVehicle: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> addVehicle({
    required String personName,
    required String vehicleName,
    required String vehicleNumber,
    required String wheelerType,
  }) async {
    try {
      final baseUrl = dotenv.env['BASE_URL'] ??
          'https://rainflowweb.com/demo/account-upgrade/api';
      final url = '$baseUrl/vehicle/add_vehicle.php';

      // Create the data as required by the API
      final vehicleData = {
        'vehicles': [
          {
            'person_name': personName,
            'vehicle_name': vehicleName,
            'vehicle_number': vehicleNumber,
            'wheeler_type': wheelerType,
          }
        ]
      };

      print('=== Vehicle Add Service ===');
      print('Making authenticated request to: $url');
      print('Vehicle Data: $vehicleData');

      final response = await ApiClient.post(
        url,
        vehicleData,
        isFormData: true,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Vehicle added');
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
        'error': {
          'code': e.errorCode ?? 'UNKNOWN',
          'message': e.message,
        },
      };
    } catch (e, stackTrace) {
      print('Exception in addVehicle: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}
