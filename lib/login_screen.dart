import 'package:flutter/material.dart';
import 'db_helper.dart'; 
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<AppUser> loginUsers = [];
  AppUser? selectedUser;
  final TextEditingController pinController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoginUsers();
  }

  Future<void> _loadLoginUsers() async {
    final users = await DBHelper.getLoginUsers();
    setState(() {
      loginUsers = users;
      if (users.isNotEmpty) selectedUser = users.first;
      isLoading = false;
    });
  }

  void _login() {
    if (selectedUser == null) return;

    if (pinController.text == selectedUser!.pin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(currentUser: selectedUser!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رمز الدخول (PIN) غير صحيح!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withOpacity(0.08),
                    Colors.white,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 55,
                              width: 65,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    left: 4,
                                    child: Text(
                                      'O',
                                      style: TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF1E232A),
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [Color(0xFF00A2FF), Color(0xFF0052FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: const Text(
                                        'S',
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Omar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E232A),
                                  ),
                                ),
                                Text(
                                  '_soft',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0052FF),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'مرحباً بك ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'الرجاء اختيار المستخدم وإدخال رمز الدخول',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<AppUser>(
                              value: selectedUser,
                              decoration: InputDecoration(
                                labelText: 'اختر المستخدم',
                                prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              items: loginUsers.map((u) {
                                return DropdownMenuItem(value: u, child: Text(u.name));
                              }).toList(),
                              onChanged: (val) => setState(() => selectedUser = val),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: pinController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'رمز الدخول (PIN)',
                                prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _login,
                              child: const Text(
                                'تسجيل الدخول',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
