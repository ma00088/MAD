import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';

class BookingProvider extends ChangeNotifier {
  // Firebase service instance
  final FirestoreService _firestoreService = FirestoreService();
  
  // State variables
  List<BusModel> _availableBuses = [];
  List<BookingModel> _userBookings = [];
  BusModel? _selectedBus;
  String _promoCode = '';
  int _discount = 0;
  
  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BusModel> get availableBuses => _availableBuses;
  List<BookingModel> get userBookings => _userBookings;
  BusModel? get selectedBus => _selectedBus;
  int get discount => _discount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor
  BookingProvider() {
    // Don't load mock data here anymore
  }

  // ========== FIREBASE METHODS ==========

  // Load available buses from Firebase based on route
  Future<void> loadAvailableBuses(String from, String to) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('🟡 Provider: Loading buses for route $from → $to');
      
      // Get schedules from Firestore
      final QuerySnapshot schedules = await _firestoreService.getSchedulesByRoute(from, to);
      
      print('🟢 Provider: Found ${schedules.docs.length} total schedules for route');
      
      // Convert to BusModel list
      _availableBuses = [];
      
      for (var doc in schedules.docs) {
        BusModel bus = BusModel.fromFirestore(doc);
        _availableBuses.add(bus);
        print('   Schedule: ${bus.departureTime}, Bus: ${bus.companyName}');
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('🔴 Provider Error loading buses: $e');
      _setError('Failed to load buses: $e');
      _setLoading(false);
    }
  }

  // Load available buses with time and date filter
  Future<void> loadAvailableBusesWithTime(
    String from, 
    String to, 
    String time,
    DateTime date
  ) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('🟡 Provider: Loading buses with time filter');
      print('   From: $from, To: $to');
      print('   Time: $time, Date: $date');
      print('   Day of week: ${date.weekday} (1=Mon, 7=Sun)');
      
      // Get schedules from Firestore with time and date filter
      final QuerySnapshot schedules = await _firestoreService.getSchedulesByRouteAndTime(
        from, to, time, date
      );
      
      print('🟢 Provider: Found ${schedules.docs.length} schedules matching criteria');
      
      // Convert to BusModel list
      _availableBuses = [];
      
      for (var doc in schedules.docs) {
        print('   Processing schedule doc: ${doc.id}');
        BusModel bus = BusModel.fromFirestore(doc);
        _availableBuses.add(bus);
        print('   ✅ Added bus: ${bus.departureTime} - ${bus.companyName}');
      }
      
      if (_availableBuses.isEmpty) {
        print('⚠️ Provider: No buses available after filtering');
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('🔴 Provider Error: $e');
      _setError('Failed to load buses: $e');
      _setLoading(false);
    }
  }

  // Load user's bookings from Firebase
  Future<void> loadUserBookings(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('🟡 Provider: Loading bookings for user $userId');
      
      final QuerySnapshot bookings = await _firestoreService.getUserBookings(userId);
      
      _userBookings = [];
      for (var doc in bookings.docs) {
        BookingModel booking = BookingModel.fromFirestore(doc);
        _userBookings.add(booking);
      }
      
      print('🟢 Provider: Found ${_userBookings.length} bookings');
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('🔴 Provider Error loading bookings: $e');
      _setError('Failed to load bookings: $e');
      _setLoading(false);
    }
  }

  // Create a new booking in Firebase - UPDATED to return bookingId
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String scheduleId,
    required List<int> seats,
    required double amount,
    String? promoCode,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('🟡 Provider: Creating booking for user $userId');
      print('   Schedule: $scheduleId, Seats: $seats, Amount: $amount');
      
      // Create booking in Firestore
      String bookingId = await _firestoreService.createBooking(
        userId: userId,
        scheduleId: scheduleId,
        seats: seats,
        amount: amount,
        promoCode: promoCode,
      );
      
      print('🟢 Provider: Booking created with ID: $bookingId');
      
      // Update available seats
      await _firestoreService.updateAvailableSeats(scheduleId, seats.length);
      print('🟢 Provider: Updated available seats');
      
      // Refresh user bookings after successful booking
      await loadUserBookings(userId);
      
      _setLoading(false);
      
      // Return both success status and bookingId
      return {
        'success': true,
        'bookingId': bookingId,
      };
    } catch (e) {
      print('🔴 Provider Error creating booking: $e');
      _setError('Failed to create booking: $e');
      _setLoading(false);
      return {
        'success': false,
        'bookingId': null,
      };
    }
  }

  // Get a single booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      print('🟡 Provider: Getting booking by ID: $bookingId');
      
      DocumentSnapshot bookingDoc = await _firestoreService.getBooking(bookingId);
      if (bookingDoc.exists) {
        print('🟢 Provider: Booking found');
        return BookingModel.fromFirestore(bookingDoc);
      }
      print('⚠️ Provider: Booking not found');
      return null;
    } catch (e) {
      print('🔴 Provider Error getting booking: $e');
      return null;
    }
  }

  // ========== EXISTING METHODS ==========

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

  // Add booking to local list (for immediate UI update)
  Future<void> addBooking(BookingModel booking) async {
    _userBookings.insert(0, booking);
    notifyListeners();
  }

  // ========== HELPER METHODS ==========

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // For demo/testing - keep mock data temporarily
  void loadMockData() {
    _availableBuses = [
      BusModel(
        id: '1',
        companyName: 'MetroLine',
        departureTime: '11:00 AM',
        arrivalTime: '03:30 PM',
        fromLocation: 'New York City',
        toLocation: 'DC Union Station',
        price: 1,  // CHANGED: 35 → 1
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
        price: 1,  // CHANGED: 25 → 1
        originalPrice: 2,  // CHANGED: 35 → 2 (for discount display)
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
        price: 1,  // CHANGED: 25 → 1
        seatsLeft: 4,
        hasWifi: true,
        rating: 4.8,
      ),
    ];
    notifyListeners();
  }
}