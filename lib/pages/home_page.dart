import 'package:flutter/material.dart';
import 'package:finbro/pages/history_page.dart';
import 'package:finbro/pages/add_expense_page.dart';
import 'package:finbro/pages/login_page.dart';
import 'package:finbro/widgets/expense_item.dart';
import 'package:finbro/modals/expense.dart';
import 'package:finbro/services/expense_service.dart';
import 'package:finbro/services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ExpenseService _expenseService = ExpenseService();
  final AuthService _authService = AuthService();
  List<Expense> _todayExpenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayExpenses();
  }

  Future<void> _fetchTodayExpenses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final allExpenses = await _expenseService.getHistory();
      final now = DateTime.now();
      _todayExpenses = allExpenses.where((expense) {
        return expense.date.year == now.year &&
            expense.date.month == now.month &&
            expense.date.day == now.day;
      }).toList();
      print('Fetched today\'s expenses: ${_todayExpenses.length}');
    } catch (e) {
      print('Error fetching today\'s expenses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load today\'s expenses: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.clearAllData(); // Call the new function
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101323),
        title: const Text(
          'Expenses',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 24, bottom: 12),
            child: Text(
              'Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchTodayExpenses,
                    color: Colors.white,
                    backgroundColor: const Color(0xFF607afb),
                    child: _todayExpenses.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'No expenses for today.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _todayExpenses.length,
                            itemBuilder: (context, index) {
                              final expense = _todayExpenses[index];
                              return ExpenseItem(
                                amount: expense.amount,
                                category: expense.category,
                                icon: Icons.category,
                                color: const Color(0xFF21284a),
                              );
                            },
                          ),
                  ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddExpensePage(),
                    ),
                  );
                  // Manually refresh after adding an expense
                  _fetchTodayExpenses();
                },
                backgroundColor: const Color(0xFF607afb),
                label: const Text(
                  'Add Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
          _buildBottomNavigationBar(context),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF181d35),
        border: Border(top: BorderSide(color: Color(0xFF21284a), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home,
            isActive: true,
            label: 'Home',
            onTap: () {},
          ),
          _buildNavItem(
            context,
            icon: Icons.history,
            isActive: false,
            label: 'History',
            onTap: () {
              // Push, don't replace. This is a navigation change, not a re-fetch.
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required bool isActive,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : const Color(0xFF8e99cc),
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF8e99cc),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
