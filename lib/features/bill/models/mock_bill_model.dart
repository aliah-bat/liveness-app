import 'bill_model.dart';

class MockBills {
  static List<BillModel> getPendingBills() {
    return [
      BillModel(
        id: '1',
        title: 'TNB Electricity Bill',
        amount: 50.00,
        dueDate: DateTime(2025, 5, 21),
        status: 'pending',
        category: 'Utilities',
      ),
      BillModel(
        id: '2',
        title: 'Sukabumi Water Bill',
        amount: 30.00,
        dueDate: DateTime(2025, 5, 20),
        status: 'pending',
        category: 'Utilities',
      ),
    ];
  }

  static List<BillModel> getPaymentHistory() {
    return [
      BillModel(
        id: '3',
        title: 'TNB Electricity Bill',
        amount: 50.00,
        dueDate: DateTime(2025, 5, 21),
        status: 'paid',
        category: 'Utilities',
      ),
      BillModel(
        id: '4',
        title: 'Sukabumi Water Bill',
        amount: 30.00,
        dueDate: DateTime(2025, 5, 20),
        status: 'overdue',
        category: 'Utilities',
      ),
      BillModel(
        id: '5',
        title: 'Internet Bill',
        amount: 100.00,
        dueDate: DateTime(2025, 5, 15),
        status: 'paid',
        category: 'Utilities',
      ),
    ];
  }

  static double getTotalPending() {
    return getPendingBills().fold(0, (sum, bill) => sum + bill.amount);
  }
}