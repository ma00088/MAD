import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingModel {
  final String id;
  final String busId;
  final String companyName;
  final DateTime bookingDate;
  final DateTime travelDate;
  final String fromLocation;
  final String toLocation;
  final String departureTime;
  final String arrivalTime;
  final int price;
  final int discount;
  final int total;
  final String status;
  final String qrCode;
  final List<String> seats;
  
  // New fields from Firebase
  final String? userId;
  final String? scheduleId;
  final String? paymentMethod;
  final int? passengerCount;
  final String? promoCode;
  final String? bookingNumber;
  final String? busNumber;

  BookingModel({
    required this.id,
    required this.busId,
    required this.companyName,
    required this.bookingDate,
    required this.travelDate,
    required this.fromLocation,
    required this.toLocation,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.discount,
    required this.total,
    required this.status,
    required this.qrCode,
    required this.seats,
    // New optional fields
    this.userId,
    this.scheduleId,
    this.paymentMethod,
    this.passengerCount,
    this.promoCode,
    this.bookingNumber,
    this.busNumber,
  });

  // ========== FROM JSON ==========
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      busId: json['busId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      bookingDate: json['bookingDate'] != null 
          ? DateTime.parse(json['bookingDate'].toString()) 
          : DateTime.now(),
      travelDate: json['travelDate'] != null 
          ? DateTime.parse(json['travelDate'].toString()) 
          : DateTime.now(),
      fromLocation: json['fromLocation']?.toString() ?? '',
      toLocation: json['toLocation']?.toString() ?? '',
      departureTime: json['departureTime']?.toString() ?? '',
      arrivalTime: json['arrivalTime']?.toString() ?? '',
      price: json['price'] != null ? int.tryParse(json['price'].toString()) ?? 0 : 0,
      discount: json['discount'] != null ? int.tryParse(json['discount'].toString()) ?? 0 : 0,
      total: json['total'] != null ? int.tryParse(json['total'].toString()) ?? 0 : 0,
      status: json['status']?.toString() ?? 'pending',
      qrCode: json['qrCode']?.toString() ?? '',
      seats: json['seats'] != null 
          ? List<String>.from(json['seats'].map((x) => x.toString())) 
          : [],
      // New fields from JSON
      userId: json['userId']?.toString(),
      scheduleId: json['scheduleId']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      passengerCount: json['passengerCount'] != null 
          ? int.tryParse(json['passengerCount'].toString()) 
          : null,
      promoCode: json['promoCode']?.toString(),
      bookingNumber: json['bookingNumber']?.toString(),
      busNumber: json['busNumber']?.toString(),
    );
  }

  // ========== FROM FIRESTORE (FIXED) ==========
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Helper function to safely extract ID from DocumentReference
    String getIdFromReference(dynamic ref) {
      if (ref == null) return '';
      if (ref is DocumentReference) {
        return ref.id;
      }
      if (ref is String) {
        // Check if it's a path like "users/abc123"
        if (ref.contains('/')) {
          return ref.split('/').last;
        }
        return ref;
      }
      return ref.toString();
    }

    // Helper function to safely get int value
    int toInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper function to safely get string value
    String getString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Timestamp) return value.toDate().toIso8601String();
      return value.toString();
    }

    // Helper function to safely get DateTime
    DateTime getDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    // Handle timestamp conversion
    DateTime bookingDateTime = getDateTime(data['bookingDate']);
    DateTime travelDateTime = getDateTime(data['travelDate']);
    
    // Handle seats conversion
    List<String> seatList = [];
    if (data['seats'] != null) {
      if (data['seats'] is List) {
        seatList = (data['seats'] as List).map((seat) => seat.toString()).toList();
      } else if (data['seats'] is String) {
        // Handle comma-separated string
        seatList = (data['seats'] as String).split(',').map((s) => s.trim()).toList();
      }
    }
    
    // Get schedule reference if exists - FIXED
    String scheduleId = getIdFromReference(data['scheduleId']);
    
    // Get user reference if exists - FIXED
    String userId = getIdFromReference(data['userId']);
    
    // Get bus reference if exists - FIXED
    String busId = getIdFromReference(data['busId']);
    if (busId.isEmpty) {
      busId = data['scheduleId']?.toString() ?? scheduleId;
    }
    
    // Calculate total if not provided - FIXED: Changed default from 25 to 1
    int totalAmount = toInt(data['totalAmount'] ?? data['total'] ?? 1);
    int priceAmount = toInt(data['price'] ?? data['ticketPrice'] ?? 1);
    int discountAmount = toInt(data['discount'] ?? data['discountAmount']);
    
    if (totalAmount == 0 && priceAmount > 0) {
      totalAmount = priceAmount - discountAmount;
    }
    
    return BookingModel(
      id: doc.id,
      busId: busId,
      companyName: getString(data['companyName'] ?? data['busName'], 'UTB Bus'),
      bookingDate: bookingDateTime,
      travelDate: travelDateTime,
      fromLocation: getString(data['fromLocation'] ?? data['source'], 'Isa Town'),
      toLocation: getString(data['toLocation'] ?? data['destination'], 'UTB Campus'),
      departureTime: getString(data['departureTime'], '07:30 AM'),
      arrivalTime: getString(data['arrivalTime'], '08:00 AM'),
      price: priceAmount,
      discount: discountAmount,
      total: totalAmount,
      status: getString(data['paymentStatus'] ?? data['bookingStatus'], 'confirmed'),
      qrCode: getString(data['qrCode'], 'QR${DateTime.now().millisecondsSinceEpoch}'),
      seats: seatList,
      // New fields
      userId: userId,
      scheduleId: scheduleId,
      paymentMethod: getString(data['paymentMethod']),
      passengerCount: toInt(data['passengers'] ?? data['passengerCount'], seatList.length),
      promoCode: getString(data['promoCode']),
      bookingNumber: getString(data['bookingNumber'] ?? data['bookingId'], doc.id),
      busNumber: getString(data['busNumber']),
    );
  }

  // ========== TO JSON ==========
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busId': busId,
      'companyName': companyName,
      'bookingDate': bookingDate.toIso8601String(),
      'travelDate': travelDate.toIso8601String(),
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'price': price,
      'discount': discount,
      'total': total,
      'status': status,
      'qrCode': qrCode,
      'seats': seats,
      // New fields
      'userId': userId,
      'scheduleId': scheduleId,
      'paymentMethod': paymentMethod,
      'passengerCount': passengerCount,
      'promoCode': promoCode,
      'bookingNumber': bookingNumber,
      'busNumber': busNumber,
    };
  }

  // ========== TO FIRESTORE ==========
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId != null ? FirebaseFirestore.instance.collection('users').doc(userId) : null,
      'scheduleId': scheduleId != null ? FirebaseFirestore.instance.collection('schedules').doc(scheduleId) : null,
      'companyName': companyName,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'travelDate': travelDate.toIso8601String(),
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'price': price,
      'discount': discount,
      'totalAmount': total,
      'paymentStatus': status,
      'qrCode': qrCode,
      'seats': seats.map((s) => int.tryParse(s) ?? s).toList(),
      'paymentMethod': paymentMethod,
      'passengers': passengerCount ?? seats.length,
      'promoCode': promoCode,
      'bookingNumber': bookingNumber ?? id,
      'busNumber': busNumber,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ========== HELPER METHODS ==========

  // Get formatted booking date
  String get formattedBookingDate {
    return '${bookingDate.day.toString().padLeft(2, '0')}.${bookingDate.month.toString().padLeft(2, '0')}.${bookingDate.year}';
  }

  // Get formatted travel date
  String get formattedTravelDate {
    return '${travelDate.day.toString().padLeft(2, '0')}.${travelDate.month.toString().padLeft(2, '0')}.${travelDate.year}';
  }

  // Get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // Check if booking is upcoming
  bool get isUpcoming {
    return travelDate.isAfter(DateTime.now()) && status != 'cancelled';
  }

  // Check if booking is past
  bool get isPast {
    return travelDate.isBefore(DateTime.now());
  }

  // Get seat numbers as string
  String get seatsAsString {
    return seats.join(', ');
  }

  // Get passenger count
  int get passengerCountValue {
    return passengerCount ?? seats.length;
  }

  // Get route string
  String get routeString {
    return '$fromLocation → $toLocation';
  }

  // Get time string
  String get timeString {
    return '$departureTime - $arrivalTime';
  }
}