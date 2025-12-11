import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_model.dart';

class BillService {
  final _supabase = Supabase.instance.client;

  Future<void> createBill({
    required String title,
    required double amount,
    required DateTime dueDate,
    String? imageUrl,
    String? rawText,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('bills').insert({
      'user_id': userId,
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'status': 'unpaid',
      'image_url': imageUrl,
      'raw_text': rawText,
    });
  }

  Future<List<BillModel>> getPendingBills() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('bills')
        .select()
        .eq('user_id', userId)
        .eq('status', 'unpaid')
        .order('due_date', ascending: true);

    return (data as List).map((bill) => BillModel.fromJson(bill)).toList();
  }

  Future<List<BillModel>> getPaymentHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _supabase
        .from('bills')
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['paid', 'overdue']) 
        .order('due_date', ascending: false);

    return (data as List).map((bill) => BillModel.fromJson(bill)).toList();
  }

  Future<void> markAsPaid(String billId) async {
    await _supabase
        .from('bills')
        .update({'status': 'paid'})
        .eq('id', billId);
  }

  Future<double> getTotalPending() async {
    final bills = await getPendingBills();
    return bills.fold<double>(0.0, (sum, bill) => sum + bill.amount);
  }
}