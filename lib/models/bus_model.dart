import 'package:cloud_firestore/cloud_firestore.dart';

class BusModel {
  final String id;
  final String companyName;
  final String departureTime;
  final String arrivalTime;
  final String fromLocation;
  final String toLocation;
  final String? busClass;
  final int price;
  final int? originalPrice;
  final int? seatsLeft;
  final bool hasWifi;
  final double rating;
  final String? imageUrl;
  
  // New fields from Firebase
  final String? busNumber;
  final String? routeName;
  final List<String>? operatingDays;
  final int? totalSeats;
  final int? availableSeats;

  BusModel({
    required this.id,
    required this.companyName,
    required this.departureTime,
    required this.arrivalTime,
    required this.fromLocation,
    required this.toLocation,
    this.busClass,
    required this.price,
    this.originalPrice,
    this.seatsLeft,
    this.hasWifi = false,
    this.rating = 0,
    this.imageUrl,
    // New optional fields
    this.busNumber,
    this.routeName,
    this.operatingDays,
    this.totalSeats,
    this.availableSeats,
  });

  // ========== HELPER FUNCTIONS FOR TYPE SAFETY ==========
  
  // Safely convert any value to int
  static int _toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Safely convert any value to double
  static double _toDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Safely convert to boolean
  static bool _toBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value == 1;
    return defaultValue;
  }

  // ========== FROM JSON (keep existing) ==========
  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      departureTime: json['departureTime']?.toString() ?? '',
      arrivalTime: json['arrivalTime']?.toString() ?? '',
      fromLocation: json['fromLocation']?.toString() ?? '',
      toLocation: json['toLocation']?.toString() ?? '',
      busClass: json['busClass']?.toString(),
      price: _toInt(json['price'], 0),
      originalPrice: json['originalPrice'] != null ? _toInt(json['originalPrice']) : null,
      seatsLeft: json['seatsLeft'] != null ? _toInt(json['seatsLeft']) : null,
      hasWifi: _toBool(json['hasWifi'], false),
      rating: _toDouble(json['rating'], 0.0),
      imageUrl: json['imageUrl']?.toString(),
      // New fields from JSON
      busNumber: json['busNumber']?.toString(),
      routeName: json['routeName']?.toString(),
      operatingDays: json['operatingDays'] != null 
          ? List<String>.from(json['operatingDays'].map((x) => x.toString())) 
          : null,
      totalSeats: json['totalSeats'] != null ? _toInt(json['totalSeats']) : null,
      availableSeats: json['availableSeats'] != null ? _toInt(json['availableSeats']) : null,
    );
  }

  // ========== FROM FIRESTORE (FIXED) ==========
  factory BusModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Helper function to safely get string values
    String getString(String key, [String defaultValue = '']) {
      return data[key]?.toString() ?? defaultValue;
    }
    
    // Handle the case where we're getting a schedule document
    // that references bus and route documents
    String companyName = getString('busName', 'UTB Bus');
    String busNumber = getString('busNumber', 'B-12');
    String fromLocation = getString('source', getString('fromLocation', 'Isa Town'));
    String toLocation = getString('destination', getString('toLocation', 'UTB Campus'));
    String routeName = getString('routeName', '$fromLocation → $toLocation');
    
    // Get price and convert safely (Firestore numbers come as double)
    int price = _toInt(data['price'], 25);
    
    // Get seats data safely
    int totalSeats = _toInt(data['totalSeats'], 40);
    int availableSeats = _toInt(data['availableSeats'], totalSeats);
    int seatsLeft = _toInt(data['seatsLeft'], availableSeats);
    
    // Get rating safely
    double rating = _toDouble(data['rating'], 4.5);
    
    // Get operating days safely
    List<String> operatingDays = [];
    if (data['operatingDays'] != null) {
      if (data['operatingDays'] is List) {
        operatingDays = (data['operatingDays'] as List)
            .map((day) => day.toString())
            .toList();
      }
    } else {
      operatingDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    }
    
    // Get boolean values safely
    bool hasWifi = _toBool(data['hasWifi'], true);
    
    return BusModel(
      id: doc.id,
      companyName: companyName,
      departureTime: getString('departureTime', '07:30 AM'),
      arrivalTime: getString('arrivalTime', '08:00 AM'),
      fromLocation: fromLocation,
      toLocation: toLocation,
      busClass: getString('busType', 'Standard'),
      price: price,
      originalPrice: data['originalPrice'] != null ? _toInt(data['originalPrice']) : null,
      seatsLeft: seatsLeft,
      hasWifi: hasWifi,
      rating: rating,
      imageUrl: getString('imageUrl'),
      // New fields
      busNumber: busNumber,
      routeName: routeName,
      operatingDays: operatingDays,
      totalSeats: totalSeats,
      availableSeats: availableSeats,
    );
  }

  // ========== TO JSON (keep existing) ==========
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'busClass': busClass,
      'price': price,
      'originalPrice': originalPrice,
      'seatsLeft': seatsLeft,
      'hasWifi': hasWifi,
      'rating': rating,
      'imageUrl': imageUrl,
      // New fields
      'busNumber': busNumber,
      'routeName': routeName,
      'operatingDays': operatingDays,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
    };
  }

  // ========== HELPER METHODS ==========
  
  // Check if bus operates on a specific day
  bool operatesOnDay(String day) {
    if (operatingDays == null || operatingDays!.isEmpty) return true;
    return operatingDays!.contains(day);
  }

  // Get formatted route string
  String get routeString => '$fromLocation → $toLocation';

  // Get bus display name
  String get displayName => busNumber != null ? 'Bus $busNumber' : companyName;

  // Check if seats are available
  bool get hasSeatsAvailable => (seatsLeft ?? 0) > 0;

  // Get discount percentage if original price exists
  int? get discountPercentage {
    if (originalPrice != null && originalPrice! > price) {
      return ((originalPrice! - price) / originalPrice! * 100).round();
    }
    return null;
  }
}