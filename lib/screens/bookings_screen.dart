import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/booking_provider.dart';
import '../utils/theme.dart';
import 'ticket_screen.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure this runs after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserBookings();
    });
  }

  Future<void> _loadUserBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final provider = Provider.of<BookingProvider>(context, listen: false);
        await provider.loadUserBookings(user.uid);
      } else {
        setState(() {
          _errorMessage = 'Please log in to view your bookings';
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        _errorMessage = 'Failed to load bookings. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBookings() async {
    await _loadUserBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refreshBookings,
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          // Show loading state
          if (_isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your bookings...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Show error state
          if (_errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshBookings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          // Show empty state
          if (provider.userBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bookmark_border,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No bookings yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Book your first bus ride now!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Book a Trip'),
                  ),
                ],
              ),
            );
          }

          // Show bookings list
          return RefreshIndicator(
            onRefresh: _refreshBookings,
            color: AppColors.primary,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: provider.userBookings.length,
              itemBuilder: (context, index) {
                final booking = provider.userBookings[index];
                return _buildBookingCard(booking, context);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking, BuildContext context) {
    // Determine status color
    Color statusColor = Colors.green;
    String statusText = booking.status?.toString().toLowerCase() ?? 'confirmed';
    
    if (statusText == 'pending') {
      statusColor = Colors.orange;
    } else if (statusText == 'cancelled') {
      statusColor = Colors.red;
    } else if (statusText == 'completed') {
      statusColor = Colors.blue;
    }

    // Format dates safely
    String formattedDate = '';
    try {
      if (booking.travelDate != null) {
        formattedDate = '${booking.travelDate.day}.${booking.travelDate.month}.${booking.travelDate.year}';
      }
    } catch (e) {
      formattedDate = 'Date not available';
    }
    
    // Get booking number safely
    String bookingNumber = '';
    if (booking.bookingNumber != null) {
      bookingNumber = booking.bookingNumber!;
    } else if (booking.id != null) {
      bookingNumber = booking.id.substring(0, booking.id.length > 8 ? 8 : booking.id.length);
    } else {
      bookingNumber = 'N/A';
    }
    
    return GestureDetector(
      onTap: () {
        // Navigate to ticket screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketScreen(
              bookingId: booking.id,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and booking number
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusText == 'pending' 
                              ? Icons.access_time
                              : statusText == 'cancelled'
                                  ? Icons.cancel
                                  : Icons.check_circle,
                          size: 14,
                          color: statusColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          statusText.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ID: $bookingNumber',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Bus company and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.companyName ?? 'UTB Bus',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${booking.seats?.length ?? 0} seat(s)',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Route with times
              Row(
                children: [
                  // From
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.departureTime ?? '--:--',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          booking.fromLocation ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow with duration
                  Column(
                    children: [
                      Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
                      SizedBox(height: 2),
                      Text(
                        _calculateDuration(booking.departureTime ?? '', booking.arrivalTime ?? ''),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  
                  // To
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          booking.arrivalTime ?? '--:--',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          booking.toLocation ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 8),
              
              // Seats and price - FIXED
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Seat numbers
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seats',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2),
                        // FIXED: Properly handle the seats list
                        Wrap(
                          spacing: 4,
                          children: (booking.seats != null && booking.seats is List)
                              ? List<Widget>.from(
                                  (booking.seats as List).map<Widget>((seat) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        seat.toString(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                )
                              : [],
                        ),
                      ],
                    ),
                  ),
                  
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Paid',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '\$${booking.total ?? 0}.00',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // View ticket button
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketScreen(
                          bookingId: booking.id,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.confirmation_number, size: 16),
                  label: Text('View E-Ticket'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDuration(String departure, String arrival) {
    try {
      if (departure.isEmpty || arrival.isEmpty) return '?h';
      
      // Handle different time formats
      String depStr = departure.split(' ')[0]; // Remove AM/PM if present
      String arrStr = arrival.split(' ')[0];
      
      int depHour = int.parse(depStr.split(':')[0]);
      int arrHour = int.parse(arrStr.split(':')[0]);
      int duration = arrHour - depHour;
      if (duration < 0) duration += 12;
      return '${duration}h';
    } catch (e) {
      return '1h';
    }
  }
}