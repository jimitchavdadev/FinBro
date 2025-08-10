import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:finbro/pages/login_page.dart';
import 'package:finbro/pages/home_page.dart';
import 'package:finbro/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finbro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheckWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthCheckWrapper extends StatelessWidget {
  const AuthCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService().getToken(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          if (snapshot.hasData && snapshot.data != null) {
            // JWT token found, navigate to HomePage
            print('JWT token found: ${snapshot.data}');
            return const HomePage();
          } else {
            // No JWT token found, navigate to LoginPage
            print('No JWT token found. Navigating to Login Page.');
            return const LoginPage();
          }
        }
      },
    );
  }
}
