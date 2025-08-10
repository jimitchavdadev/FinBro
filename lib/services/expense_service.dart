import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:finbro/modals/expense.dart';
import 'package:finbro/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseService {
  final String _baseUrl = dotenv.env['BASE_URL']!;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      return Future.error('Authorization token not found.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- Local Storage Methods ---
  Future<void> _saveHistoryToCache(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString('expense_history', jsonString);
    print('ExpenseService: History saved to local cache.');
  }

  Future<List<Expense>?> _getHistoryFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('expense_history');
    if (jsonString == null) {
      print('ExpenseService: No history found in local cache.');
      return null;
    }
    final List<dynamic> data = json.decode(jsonString);
    print('ExpenseService: Loaded history from local cache.');
    return data.map((item) => Expense.fromJson(item)).toList();
  }
  // --- End Local Storage Methods ---

  Future<Expense> addExpense(Expense newExpense) async {
    final url = Uri.parse('$_baseUrl/expenses');
    print(
      'ExpenseService: Attempting to POST to $url with data: ${newExpense.toJson()}',
    );
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(url, headers: headers, body: json.encode(newExpense.toJson()))
          .timeout(const Duration(seconds: 10));

      print(
        'ExpenseService: Received response from $url with status code ${response.statusCode}',
      );
      print('ExpenseService: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Expense.fromJson(data);
      } else {
        final error =
            json.decode(response.body)['message'] ?? 'Failed to add expense.';
        return Future.error(error);
      }
    } on TimeoutException catch (e) {
      print('ExpenseService: Connection timed out to $url: $e');
      return Future.error('Connection timed out. Please check your network.');
    } catch (e) {
      print('ExpenseService: Failed to connect to $url: $e');
      return Future.error('Failed to connect to the server.');
    }
  }

  // Updated getHistory method to use local cache
  Future<List<Expense>> getHistory({
    bool forceRefresh = false,
    String? category,
  }) async {
    if (!forceRefresh) {
      final cachedHistory = await _getHistoryFromCache();
      if (cachedHistory != null) {
        return cachedHistory;
      }
    }

    // If cache is empty or a refresh is forced, fetch from API
    String endpoint = '$_baseUrl/history';
    if (category != null) {
      endpoint += '?category=$category';
    }
    final url = Uri.parse(endpoint);
    print('ExpenseService: Attempting to GET from $url');

    try {
      final headers = await _getHeaders();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      print(
        'ExpenseService: Received response from $url with status code ${response.statusCode}',
      );
      print('ExpenseService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final fetchedExpenses = data
            .map((item) => Expense.fromJson(item))
            .toList();
        await _saveHistoryToCache(fetchedExpenses); // Save to cache
        return fetchedExpenses;
      } else {
        final error =
            json.decode(response.body)['message'] ?? 'Failed to fetch history.';
        return Future.error(error);
      }
    } on TimeoutException catch (e) {
      print('ExpenseService: Connection timed out to $url: $e');
      return Future.error('Connection timed out. Please check your network.');
    } catch (e) {
      print('ExpenseService: Failed to connect to $url: $e');
      return Future.error('Failed to connect to the server.');
    }
  }

  Future<void> deleteExpense(int? expenseId) async {
    if (expenseId == null) {
      return Future.error('Expense ID is missing.');
    }

    final url = Uri.parse('$_baseUrl/expenses/$expenseId');
    print('ExpenseService: Attempting to DELETE from $url');

    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      print(
        'ExpenseService: Received response from $url with status code ${response.statusCode}',
      );

      if (response.statusCode != 204) {
        final error =
            json.decode(response.body)['message'] ??
            'Failed to delete expense.';
        return Future.error(error);
      }

      // After successful deletion, refresh the cache
      final cachedHistory = await _getHistoryFromCache();
      if (cachedHistory != null) {
        cachedHistory.removeWhere((expense) => expense.id == expenseId);
        await _saveHistoryToCache(cachedHistory);
        print('ExpenseService: Expense with ID $expenseId deleted from cache.');
      }
    } on TimeoutException catch (e) {
      print('ExpenseService: Connection timed out to $url: $e');
      return Future.error('Connection timed out. Please check your network.');
    } catch (e) {
      print('ExpenseService: Failed to connect to $url: $e');
      return Future.error('Failed to connect to the server.');
    }
  }
}
