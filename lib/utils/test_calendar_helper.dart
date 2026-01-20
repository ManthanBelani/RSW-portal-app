// import '../services/general_calendar_service.dart';
//
// class TestCalendarHelper {
//   static Future<void> testCalendarService() async {
//     print('🧪 Testing Calendar Service...');
//
//     try {
//       final result = await GeneralCalendarService.getGeneralCalendarData();
//
//       if (result != null) {
//         print('✅ Calendar Service Test - SUCCESS');
//         print('📊 Response Data: $result');
//
//         if (result['success'] == true) {
//           print('🎉 API returned success: true');
//           if (result['data'] != null) {
//             if (result['data'] is List) {
//               print('📅 Calendar events count: ${(result['data'] as List).length}');
//             } else {
//               print('📅 Calendar data type: ${result['data'].runtimeType}');
//             }
//           }
//         } else {
//           print('⚠️ API returned success: false');
//           if (result['error'] != null) {
//             print('❌ Error: ${result['error']}');
//           }
//         }
//       } else {
//         print('❌ Calendar Service Test - FAILED (null response)');
//       }
//     } catch (e, stackTrace) {
//       print('💥 Calendar Service Test - EXCEPTION');
//       print('Error: $e');
//       print('Stack trace: $stackTrace');
//     }
//   }
// }