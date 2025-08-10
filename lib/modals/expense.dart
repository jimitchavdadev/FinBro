// lib/modals/expense.dart

import 'package:flutter/material.dart';

class Expense {
  final double amount;
  final String category;
  final DateTime date;
  final IconData? icon;
  final String? notes;
  final int? id;

  Expense({
    required this.amount,
    required this.category,
    required this.date,
    this.icon,
    this.notes,
    this.id,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    // Determine the type of the 'amount' field and handle it accordingly
    final amountValue = json['amount'];
    double parsedAmount;

    if (amountValue is String) {
      parsedAmount = double.parse(amountValue);
    } else if (amountValue is num) {
      parsedAmount = amountValue.toDouble();
    } else {
      // Handle unexpected types gracefully
      parsedAmount = 0.0;
    }

    return Expense(
      id: json['id'] as int?,
      amount: parsedAmount,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}
