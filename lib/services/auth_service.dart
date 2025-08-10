import 'dart:async'; // Add this import for TimeoutException
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<String?> login(String phoneNumber, String password) async {
    final url = Uri.parse('$_baseUrl/auth');
    print('AuthService: Attempting to POST to $url');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'phoneNumber': phoneNumber,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10)); // Added timeout

      print(
        'AuthService: Received response from $url with status code ${response.statusCode}',
      );
      print('AuthService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        await _storage.write(key: 'jwt_token', value: token);
        return token;
      } else {
        final data = json.decode(response.body);
        return Future.error(data['message'] ?? 'Authentication failed');
      }
    } on TimeoutException catch (e) {
      print('AuthService: Connection timed out to $url: $e');
      return Future.error('Connection timed out. Please check your network.');
    } catch (e) {
      print('AuthService: Failed to connect to $url: $e');
      return Future.error('Failed to connect to the server.');
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // New method to clear all data on logout
  Future<void> clearAllData() async {
    await _storage.delete(key: 'jwt_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('expense_history');
    print('AuthService: All user data (JWT and local history) cleared.');
  }
}
