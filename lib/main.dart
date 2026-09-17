import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'login_screen.dart';

// تعريف Notifier للتحكم بالمظهر واللون الأساسي على مستوى التطبيق كامل
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<Color> primaryColorNotifier = ValueNotifier(Colors.indigo);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // جلب إعدادات المظهر المخزنة في قاعدة البيانات عند التشغيل
  final isDarkMode = await DBHelper.getSetting('dark_mode') == 'true';
  final savedColorHex = await DBHelper.getSetting('primary_color');

  if (isDarkMode) {
    themeModeNotifier.value = ThemeMode.dark;
  }

  if (savedColorHex != null && savedColorHex.isNotEmpty) {
    try {
      primaryColorNotifier.value = Color(int.parse(savedColorHex));
    } catch (_) {}
  }

  runApp(const OmarPosMasterApp());
}

class OmarPosMasterApp extends StatelessWidget {
  const OmarPosMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: primaryColorNotifier,
          builder: (context, primaryColor, _) {
            return MaterialApp(
              title: 'OmarPos',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: primaryColor,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: primaryColor,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              home: const Directionality(
                textDirection: TextDirection.rtl,
                child: LoginScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
