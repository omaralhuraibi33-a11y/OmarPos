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
        const SnackBar(content: Text('رمز الدخول (PIN) غير صحيح!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButtonFormField<AppUser>(
                    value: selectedUser,
                    decoration: const InputDecoration(labelText: 'اختر المستخدم', border: OutlineInputBorder()),
                    items: loginUsers.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u.name));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedUser = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'رمز الدخول (PIN)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                    onPressed: _login,
                    child: const Text('دخول', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }
}
