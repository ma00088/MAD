import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../models/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  List<BusModel> _availableBuses = [];
  List<BookingModel> _userBookings = [];
  BusModel? _selectedBus;
  String _promoCode = '';
  int _discount = 0;

  List<BusModel> get availableBuses => _availableBuses;
  List<BookingModel> get userBookings => _userBookings;
  BusModel? get selectedBus => _selectedBus;
  int get discount => _discount;

  BookingProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    _availableBuses = [
      BusModel(
        id: '1',
        companyName: 'MetroLine',
        departureTime: '11:00 AM',
        arrivalTime: '03:30 PM',
        fromLocation: 'New York City',
        toLocation: 'DC Union Station',
        price: 35,
        rating: 4.5,
      ),
      BusModel(
        id: '2',
        companyName: 'Express Bus Co.',
        departureTime: '09:30 AM',
        arrivalTime: '02:00 PM',
        fromLocation: 'New York City',
        toLocation: 'DC Union Station',
        busClass: 'Comfort Class',
        price: 25,
        originalPrice: 35,
        seatsLeft: 4,
        hasWifi: true,
        rating: 4.2,
      ),
      BusModel(
        id: '3',
        companyName: 'Sunrise Travels',
        departureTime: '08:00 AM',
        arrivalTime: '12:30 PM',
        fromLocation: 'NYC Central Station',
        toLocation: 'DC Union Station',
        price: 25,
        seatsLeft: 4,
        hasWifi: true,
        rating: 4.8,
      ),
    ];

    _userBookings = [
      BookingModel(
        id: 'B001',
        busId: '3',
        companyName: 'Sunrise Travels',
        bookingDate: DateTime.now().subtract(Duration(days: 2)),
        travelDate: DateTime.now().add(Duration(days: 5)),
        fromLocation: 'NYC Central Station',
        toLocation: 'DC Union Station',
        departureTime: '08:00 AM',
        arrivalTime: '12:30 PM',
        price: 25,
        discount: 5,
        total: 20,
        status: 'confirmed',
        qrCode: 'QR123456',
        seats: ['A12'],
      ),
    ];
  }

  void selectBus(BusModel bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  void applyPromoCode(String code) {
    if (code == 'FIRST20') {
      _discount = 20;
    } else {
      _discount = 0;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedBus = null;
    _discount = 0;
    _promoCode = '';
    notifyListeners();
  }

  void addBooking(BookingModel booking) {
    _userBookings.insert(0, booking);
    notifyListeners();
  }
}