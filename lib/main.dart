import 'package:flutter/material.dart';
import 'db_helper.dart'; // إذا كان بنفس المجلد، أو '../db_helper.dart' إذا كان الشاشات داخل مجلد screens
import 'login_screen.dart'; // قم بتعديل المسار حسب المجلد إذا لزم الأمر

// تعريف Notifier للتحكم بالمظهر واللون الأساسي على مستوى التطبيق كامل
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<Color> primaryColorNotifier = ValueNotifier(Colors.blue);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // جلب إعدادات المظهر المخزنة بالاعتماد على المفاتيح الموحدة
  final isDarkMode = await DBHelper.getSetting('is_dark_mode') == 'true';
  final savedColorHex = await DBHelper.getSetting('theme_color');

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
                useMaterial3: true,
                primaryColor: primaryColor,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: primaryColor,
                  primary: primaryColor,
                  brightness: Brightness.light,
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                primaryColor: primaryColor,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: primaryColor,
                  primary: primaryColor,
                  brightness: Brightness.dark,
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
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
