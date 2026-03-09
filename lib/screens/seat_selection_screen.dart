import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import 'payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String tripType;
  final String fromLocation;
  final String toLocation;
  final DateTime date;
  final DateTime? returnDate;
  final String time;
  final int passengers;
  final String? promoCode;
  final String? scheduleId;

  const SeatSelectionScreen({
    Key? key,
    required this.tripType,
    required this.fromLocation,
    required this.toLocation,
    required this.date,
    this.returnDate,
    required this.time,
    required this.passengers,
    this.promoCode,
    this.scheduleId,
  }) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  int _currentStep = 2;
  List<int> _selectedSeats = [];
  
  // Loading states
  bool _isLoading = true;
  List<int> _occupiedSeats = [];
  Map<String, dynamic>? _scheduleData;
  int _totalSeats = 40;
  double _seatPrice = 25.0;
  
  // Error state for seat loading
  bool _hasLoadError = false;

  @override
  void initState() {
    super.initState();
    _loadSeatAvailability();
  }

  // Helper function to safely convert any value to int
  int _toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper function to safely convert any value to double
  double _toDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Future<void> _loadSeatAvailability() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      print('🟡 Loading seat availability for schedule: ${widget.scheduleId}');
      
      if (widget.scheduleId == null) {
        print('⚠️ No scheduleId provided');
        setState(() {
          _isLoading = false;
          _hasLoadError = true;
        });
        return;
      }

      // Load schedule details
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(widget.scheduleId)
          .get();

      if (!scheduleDoc.exists) {
        print('⚠️ Schedule not found');
        setState(() {
          _isLoading = false;
          _hasLoadError = true;
        });
        return;
      }

      _scheduleData = scheduleDoc.data() as Map<String, dynamic>;
      print('✅ Schedule found');
      
      // Get total seats from bus reference
      if (_scheduleData!['busId'] != null) {
        DocumentReference busRef = _scheduleData!['busId'] as DocumentReference;
        DocumentSnapshot busDoc = await busRef.get();
        if (busDoc.exists) {
          Map<String, dynamic> busData = busDoc.data() as Map<String, dynamic>;
          _totalSeats = _toInt(busData['totalSeats'], 40);
          _seatPrice = _toDouble(busData['price'], 25.0);
          print('✅ Bus details: Total seats: $_totalSeats, Price: $_seatPrice');
        }
      }

      // Load bookings for this schedule on this date
      String dateStr = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
      print('🔍 Checking bookings for date: $dateStr');
      
      // Query ONLY the seats field to maintain privacy
      QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('scheduleId', isEqualTo: FirebaseFirestore.instance.doc('schedules/${widget.scheduleId}'))
          .where('travelDate', isEqualTo: dateStr)
          .where('bookingStatus', isNotEqualTo: 'cancelled')
          .get();

      print('📊 Found ${bookingsSnapshot.docs.length} existing bookings');

      // Collect all occupied seats
      Set<int> occupiedSeats = {};
      for (var doc in bookingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['seats'] != null && data['seats'] is List) {
          List<dynamic> seatsList = data['seats'] as List;
          for (var seat in seatsList) {
            int seatNum = _toInt(seat);
            if (seatNum > 0) {
              occupiedSeats.add(seatNum);
            }
          }
        }
      }
      
      setState(() {
        _occupiedSeats = occupiedSeats.toList()..sort();
      });
      print('✅ Occupied seats: $_occupiedSeats');
      
      // If no seats are occupied, show a message
      if (_occupiedSeats.isEmpty) {
        print('ℹ️ All seats are available');
      }
      
    } catch (e) {
      print('❌ Error loading seat availability: $e');
      setState(() {
        _hasLoadError = true;
      });
      
      // Show error message but don't allow booking to proceed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to verify seat availability. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
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
          'Select Seats',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                _buildStep(1, 'Trip Details', true),
                Expanded(child: _buildProgressLine(true)),
                _buildStep(2, 'Select Seats', true),
                Expanded(child: _buildProgressLine(false)),
                _buildStep(3, 'Payment', false),
              ],
            ),
          ),
          
          // Trip Summary Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fromLocation,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${widget.date.day}.${widget.date.month}.${widget.date.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: AppColors.primary),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.toLocation,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.tripType == 'roundtrip' && widget.returnDate != null) ...[
                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.sync, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Return: ${widget.returnDate!.day}.${widget.returnDate!.month}.${widget.returnDate!.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Seat Legend
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.green, 'Available'),
                _buildLegendItem(AppColors.primary, 'Selected'),
                _buildLegendItem(Colors.grey, 'Booked'),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Loading Indicator or Seat Layout or Error
          _isLoading
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading seat availability...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _hasLoadError
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Unable to Load Seats',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please go back and try again',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Go Back'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: _totalSeats,
                          itemBuilder: (context, index) {
                            int seatNumber = index + 1;
                            bool isOccupied = _occupiedSeats.contains(seatNumber);
                            bool isSelected = _selectedSeats.contains(seatNumber);
                            
                            return GestureDetector(
                              onTap: isOccupied
                                  ? null
                                  : () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedSeats.remove(seatNumber);
                                        } else if (_selectedSeats.length < widget.passengers) {
                                          _selectedSeats.add(seatNumber);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('You can only select ${widget.passengers} seat(s)'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      });
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isOccupied
                                      ? Colors.grey[300]
                                      : isSelected
                                          ? AppColors.primary
                                          : Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isOccupied
                                        ? Colors.grey
                                        : isSelected
                                            ? AppColors.primary
                                            : Colors.green,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    seatNumber.toString(),
                                    style: TextStyle(
                                      color: isOccupied
                                          ? Colors.grey
                                          : isSelected
                                              ? Colors.white
                                              : Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
          
          // Bottom Bar with Price and Continue
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '\$${(_selectedSeats.length * _seatPrice).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedSeats.length == widget.passengers && 
                             !_isLoading && 
                             !_hasLoadError
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  tripType: widget.tripType,
                                  fromLocation: widget.fromLocation,
                                  toLocation: widget.toLocation,
                                  date: widget.date,
                                  returnDate: widget.returnDate,
                                  time: widget.time,
                                  passengers: widget.passengers,
                                  selectedSeats: _selectedSeats,
                                  totalAmount: (_selectedSeats.length * _seatPrice).toInt(),
                                  promoCode: widget.promoCode,
                                  scheduleId: widget.scheduleId,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _selectedSeats.length == widget.passengers
                          ? 'Continue'
                          : 'Select ${widget.passengers} seat(s)',
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
        ],
      ),
    );
  }

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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color == AppColors.primary
                ? color
                : color == Colors.green
                    ? Colors.green[50]
                    : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color,
              width: 1,
            ),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}