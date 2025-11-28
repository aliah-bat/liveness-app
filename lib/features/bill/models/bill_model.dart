class BillModel {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String status; // 'pending', 'paid', 'overdue'
  final String? category;

  BillModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.category,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';
}