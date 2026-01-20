import 'package:url_launcher/url_launcher.dart';

class FileDownloader {
  static Future<bool> downloadFile(String url, {String? fileName}) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        print('Could not launch $url');
        return false;
      }
    } catch (e) {
      print('Error downloading file: $e');
      return false;
    }
  }
}
