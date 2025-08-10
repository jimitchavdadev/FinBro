// lib/pages/history_page.dart

import 'package:flutter/material.dart';
import 'package:finbro/modals/expense.dart';
import 'package:finbro/widgets/history_item.dart';
import 'package:finbro/pages/home_page.dart';
import 'package:finbro/pages/expense_details_page.dart';
import 'package:finbro/services/expense_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _allExpenses = [];
  String? _selectedCategory;
  bool _isLoading = false; // Set to false so the UI shows up immediately

  @override
  void initState() {
    super.initState();
    // Fetch from cache on initial load
    _fetchExpenses(forceRefresh: false);
  }

  Future<void> _fetchExpenses({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      _allExpenses = await _expenseService.getHistory(
        forceRefresh: forceRefresh,
      );
      print('Fetched ${_allExpenses.length} expenses from history.');
    } catch (e) {
      print('Error fetching expenses: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load history: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      await _expenseService.deleteExpense(expense.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully.')),
      );
      _fetchExpenses();
    } catch (e) {
      print('Error deleting expense: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete expense: $e')));
    }
  }

  List<Expense> get _filteredExpenses {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      return _allExpenses;
    }
    return _allExpenses
        .where((expense) => expense.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101323),
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF101323),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [_buildFilterButton()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: () => _fetchExpenses(
                forceRefresh: true,
              ), // Force refresh on pull-down
              color: Colors.white,

              backgroundColor: const Color(0xFF607afb),
              child: _filteredExpenses.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Pull down to load expenses.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = _filteredExpenses[index];
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ExpenseDetailsPage(
                                  expense: expense,
                                  onDelete: _deleteExpense,
                                ),
                              ),
                            );
                          },
                          child: HistoryItem(
                            amount: expense.amount,
                            category: expense.category,
                            date: expense.date,
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildFilterButton() {
    final categories = _allExpenses.map((e) => e.category).toSet().toList();
    categories.sort();
    return PopupMenuButton<String?>(
      onSelected: (String? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
      },
      icon: const Icon(Icons.filter_list, color: Colors.white),
      color: const Color(0xFF181d35),
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<String?>(
            value: null,
            child: Text('All', style: TextStyle(color: Colors.white)),
          ),
          ...categories.map((String category) {
            return PopupMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }),
        ];
      },
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
            icon: Icons.home_outlined,
            isActive: false,
            label: 'Home',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          _buildNavItem(
            context,
            icon: Icons.history,
            isActive: true,
            label: 'History',
            onTap: () {},
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
