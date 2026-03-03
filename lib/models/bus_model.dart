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
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: json['id'],
      companyName: json['companyName'],
      departureTime: json['departureTime'],
      arrivalTime: json['arrivalTime'],
      fromLocation: json['fromLocation'],
      toLocation: json['toLocation'],
      busClass: json['busClass'],
      price: json['price'],
      originalPrice: json['originalPrice'],
      seatsLeft: json['seatsLeft'],
      hasWifi: json['hasWifi'] ?? false,
      rating: json['rating']?.toDouble() ?? 0,
      imageUrl: json['imageUrl'],
    );
  }

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
    };
  }
}