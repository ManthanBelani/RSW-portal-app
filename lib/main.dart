  import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animation/loading_screen.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'services/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize notifications
  await NotificationHelper.initialize();

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        FlutterQuillLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'RSW Portal',
      theme: ThemeData(
        textTheme: GoogleFonts.publicSansTextTheme(),
        primarySwatch: Colors.red,
        primaryColor: Color(0xFFFC3342),
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: LoadingScreen(),
    );
  }
}
