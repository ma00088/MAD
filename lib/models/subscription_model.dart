import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentIdNumber;
  final String planName;
  final double price;
  final int durationDays;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool autoRenewal;
  final String? paymentMethod;

  SubscriptionModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentIdNumber,
    required this.planName,
    required this.price,
    required this.durationDays,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.autoRenewal,
    this.paymentMethod,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return SubscriptionModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Unknown',
      studentIdNumber: data['studentIdNumber'] ?? '',
      planName: data['planName'] ?? 'Subscription',
      price: (data['price'] ?? 0).toDouble(),
      durationDays: data['durationDays'] ?? 30,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      autoRenewal: data['autoRenewal'] ?? true,
      paymentMethod: data['paymentMethod'],
    );
  }

  // Helper methods
  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  bool get isExpiringSoon {
    return daysRemaining <= 7;
  }

  bool get isExpired {
    return endDate.isBefore(DateTime.now());
  }

  String get formattedStartDate {
    return "${startDate.day}/${startDate.month}/${startDate.year}";
  }

  String get formattedEndDate {
    return "${endDate.day}/${endDate.month}/${endDate.year}";
  }
}