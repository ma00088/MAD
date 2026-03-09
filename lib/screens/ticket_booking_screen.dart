import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import '../providers/booking_provider.dart';
import '../models/bus_model.dart';
import 'seat_selection_screen.dart';

class TicketBookingScreen extends StatefulWidget {
  @override
  _TicketBookingScreenState createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  // Step tracking
  int _currentStep = 1; // 1, 2, or 3
  
  // Form data
  String _tripType = 'oneway'; // 'oneway' or 'roundtrip'
  String? _selectedFrom;
  String? _selectedTo;
  DateTime? _selectedDate;
  DateTime? _returnDate;
  String? _selectedTime;
  int _passengers = 1;
  bool _hasPromoCode = false;
  final TextEditingController _promoController = TextEditingController();
  
  // Loading state for search
  bool _isSearching = false;
  
  // Locations from Firebase (will be loaded dynamically)
  List<String> _locations = [];
  
  // Available times
  final List<String> _availableTimes = ['07:00 AM', '11:00 AM', '03:00 PM'];
  
  @override
  void initState() {
    super.initState();
    _loadLocationsFromFirebase();
  }
  
  // Load unique locations from Firestore routes
  Future<void> _loadLocationsFromFirebase() async {
    try {
      // Get all routes from Firestore
      QuerySnapshot routesSnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .get();
      
      Set<String> uniqueLocations = {};
      
      for (var doc in routesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Add source location
        if (data['source'] != null) {
          uniqueLocations.add(data['source'].toString());
        }
        
        // Add destination location
        if (data['destination'] != null) {
          uniqueLocations.add(data['destination'].toString());
        }
      }
      
      // Convert to list and sort
      List<String> sortedLocations = uniqueLocations.toList()..sort();
      
      setState(() {
        _locations = sortedLocations.isNotEmpty 
            ? sortedLocations 
            : ['Isa Town', 'Riffa', 'Hamad Town', 'City Centre Bahrain', 'UTB Campus'];
      });
    } catch (e) {
      print('Error loading locations: $e');
      // Fallback to default locations
      setState(() {
        _locations = ['Isa Town', 'Riffa', 'Hamad Town', 'City Centre Bahrain', 'UTB Campus'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book Ticket',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ========== 3-STEP PROGRESS BAR ==========
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                _buildStep(1, 'Trip Details', _currentStep >= 1),
                Expanded(child: _buildProgressLine(_currentStep > 1)),
                _buildStep(2, 'Select Seats', _currentStep >= 2),
                Expanded(child: _buildProgressLine(_currentStep > 2)),
                _buildStep(3, 'Payment', _currentStep >= 3),
              ],
            ),
          ),
          
          // ========== MAIN FORM ==========
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Book tickets for your next trip!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Trip Type Selector (One Way / Round Trip)
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _tripType = 'oneway';
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _tripType == 'oneway'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'One Way',
                                  style: TextStyle(
                                    color: _tripType == 'oneway'
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: _tripType == 'oneway'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _tripType = 'roundtrip';
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _tripType == 'roundtrip'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Round Trip',
                                  style: TextStyle(
                                    color: _tripType == 'roundtrip'
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: _tripType == 'roundtrip'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // From Location
                  _buildDropdownField(
                    label: 'From',
                    value: _selectedFrom,
                    items: _locations,
                    onChanged: (value) {
                      setState(() {
                        _selectedFrom = value;
                        _selectedTo = null; // Reset destination when source changes
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // To Location
                  _buildDropdownField(
                    label: 'To',
                    value: _selectedTo,
                    items: _selectedFrom != null
                        ? _locations.where((loc) => loc != _selectedFrom).toList()
                        : _locations,
                    onChanged: (value) {
                      setState(() {
                        _selectedTo = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Date Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Date',
                          date: _selectedDate,
                          onTap: () => _selectDate(context, isReturn: false),
                        ),
                      ),
                      if (_tripType == 'roundtrip') ...[
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'Returning',
                            date: _returnDate,
                            onTap: () => _selectDate(context, isReturn: true),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Time Selection
                  Text(
                    'Select Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: _availableTimes.map((time) {
                      return Expanded(
                        child: _buildTimeChip(
                          time: time,
                          isSelected: _selectedTime == time,
                          onTap: () {
                            setState(() {
                              _selectedTime = time;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  
                  // Passengers
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Passengers',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_passengers > 1) {
                                  setState(() {
                                    _passengers--;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              '$_passengers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _passengers++;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Promo Code Toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasPromoCode = !_hasPromoCode;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _hasPromoCode
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: _hasPromoCode ? AppColors.primary : Colors.grey,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Do you have promocode?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Promo Code Input (visible when toggled)
                  if (_hasPromoCode) ...[
                    SizedBox(height: 12),
                    TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        prefixIcon: Icon(Icons.discount_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 30),
                  
                  // Search Button with loading state
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isFormValid() && !_isSearching ? _searchTrips : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSearching
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Searching...'),
                              ],
                            )
                          : Text(
                              'Search for Trips',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HELPER WIDGETS ==========
  
  Widget _buildStep(int stepNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(label),
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  date != null
                      ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: date != null ? AppColors.textPrimary : Colors.grey,
                  ),
                ),
              ],
            ),
            Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip({
    required String time,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            time,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ========== HELPER FUNCTIONS ==========

  Future<void> _selectDate(BuildContext context, {required bool isReturn}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  bool _isFormValid() {
    return _selectedFrom != null &&
        _selectedTo != null &&
        _selectedDate != null &&
        _selectedTime != null &&
        (_tripType == 'oneway' || (_tripType == 'roundtrip' && _returnDate != null));
  }

  // ========== FIXED SEARCH TRIPS METHOD ==========
  Future<void> _searchTrips() async {
    setState(() {
      _isSearching = true;
    });

    try {
      print('=== SEARCH DEBUG ===');
      print('From: $_selectedFrom');
      print('To: $_selectedTo');
      print('Time: $_selectedTime');
      print('Date: $_selectedDate');
      print('Day of week: ${_selectedDate?.weekday}'); // 1=Mon, 2=Tue, etc.
      
      // Get the provider to load available buses
      final provider = Provider.of<BookingProvider>(context, listen: false);
      
      // Use the method that filters by time AND date
      await provider.loadAvailableBusesWithTime(
        _selectedFrom!,
        _selectedTo!,
        _selectedTime!,
        _selectedDate!,
      );

      print('Total buses found after filter: ${provider.availableBuses.length}');

      // Check if any buses are available
      if (provider.availableBuses.isEmpty) {
        print('NO BUSES FOUND MATCHING CRITERIA');
        _showNoBusesDialog();
        setState(() {
          _isSearching = false;
        });
        return;
      }

      // Navigate to seat selection screen with the search criteria
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeatSelectionScreen(
            tripType: _tripType,
            fromLocation: _selectedFrom!,
            toLocation: _selectedTo!,
            date: _selectedDate!,
            returnDate: _returnDate,
            time: _selectedTime!,
            passengers: _passengers,
            promoCode: _hasPromoCode ? _promoController.text : null,
            scheduleId: provider.availableBuses.first.id,
          ),
        ),
      ).then((_) {
        // When returning from seat selection, update step
        setState(() {
          _currentStep = 2;
          _isSearching = false;
        });
      });
    } catch (e) {
      print('Error searching trips: $e');
      _showErrorDialog('Failed to search for trips. Please try again.');
      setState(() {
        _isSearching = false;
      });
    }
  }

  // ========== DIALOG METHODS ==========
  
  void _showNoBusesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'No Buses Found',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'No buses available for this route on the selected date and time. Please try different options.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}