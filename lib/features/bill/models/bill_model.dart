class BillModel {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String status;
  final String category;
  final String? imageUrl;
  final String? rawText;

  BillModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.category,
    this.imageUrl,
    this.rawText,
  });

  // From JSON (for Supabase data)
  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      category: json['category'] ?? 'Utilities', // Default category
      imageUrl: json['image_url'],
      rawText: json['raw_text'],
    );
  }

  // To JSON (for saving to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'category': category,
      'image_url': imageUrl,
      'raw_text': rawText,
    };
  }
}