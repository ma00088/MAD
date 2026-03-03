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
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      busId: json['busId'],
      companyName: json['companyName'],
      bookingDate: DateTime.parse(json['bookingDate']),
      travelDate: DateTime.parse(json['travelDate']),
      fromLocation: json['fromLocation'],
      toLocation: json['toLocation'],
      departureTime: json['departureTime'],
      arrivalTime: json['arrivalTime'],
      price: json['price'],
      discount: json['discount'],
      total: json['total'],
      status: json['status'],
      qrCode: json['qrCode'],
      seats: List<String>.from(json['seats']),
    );
  }
}