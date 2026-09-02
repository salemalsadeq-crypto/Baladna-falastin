import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

const supabaseUrl = 'https://sezepvlfxllmirshgmmm.supabase.co';
const supabaseAnonKey = 'sb_publishable_tfZzE2jzJx2o1GSFtz0v1Q_3nIKeXit';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const BaladnaApp());
}

final supabase = Supabase.instance.client;

class BaladnaApp extends StatelessWidget {
  const BaladnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بلدنا فلسطين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.oliveDeep,
        scaffoldBackgroundColor: AppColors.sandLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.oliveDeep,
          foregroundColor: Colors.white,
        ),
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const HomeScreen(),
    );
  }
}
