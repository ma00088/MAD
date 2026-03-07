import 'package:flutter/material.dart';
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
  }) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  int _currentStep = 2; // Step 2: Seat Selection
  List<int> _selectedSeats = [];
  
  // Mock seat layout (40 seats)
  final List<List<int>> _seatLayout = [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
    [13, 14, 15, 16],
    [17, 18, 19, 20],
    [21, 22, 23, 24],
    [25, 26, 27, 28],
    [29, 30, 31, 32],
    [33, 34, 35, 36],
    [37, 38, 39, 40],
  ];
  
  // Mock occupied seats
  final List<int> _occupiedSeats = [3, 4, 7, 8, 12, 15, 16, 23, 24, 31, 32];

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
          
          // Seat Layout
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: 40,
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
                        '\$${_selectedSeats.length * 25}',
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
                    onPressed: _selectedSeats.length == widget.passengers
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
                                  totalAmount: _selectedSeats.length * 25,
                                  promoCode: widget.promoCode,
                                ),
                              ),
                            );
                            // Navigate to payment
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Proceeding to payment...'),
                                backgroundColor: Colors.green,
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
                      'Continue',
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