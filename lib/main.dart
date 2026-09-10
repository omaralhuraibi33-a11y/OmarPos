import 'package:flutter/material.dart';

void main() {
  runApp(const OmarPosMasterApp());
}

class OmarPosMasterApp extends StatelessWidget {
  const OmarPosMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmarPos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // قائمة المستخدمين المتاحين في النظام
  final List<String> _users = ['مدير النظام', 'كاشير 1', 'كاشير 2', 'المشرف'];
  late String _selectedUser;

  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedUser = _users[0]; // المستخدم الافتراضي
  }

  void _login() {
    final password = _passwordController.text.trim();

    if (password == '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الدخول بنجاح! مرحباً $_selectedUser'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور غير صحيحة (التجريبي: 1234)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          // خلفية مائية باسم OmarPos
          Center(
            child: Opacity(
              opacity: 0.06,
              child: Text(
                'OmarPos',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
            ),
          ),

          // كارت نموذج تسجيل الدخول
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront,
                          size: 50,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'OmarPos',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const Text(
                        'النظام الرئيسي - تسجيل الدخول',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 30),

                      // قائمة منسدلة لاختيار المستخدم
                      DropdownButtonFormField<String>(
                        value: _selectedUser,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _users.map((String user) {
                          return DropdownMenuItem<String>(
                            value: user,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(user),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedUser = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // حقل كلمة المرور
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // زر تسجيل الدخول
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _login,
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
