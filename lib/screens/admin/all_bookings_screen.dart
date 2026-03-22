import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../ticket_screen.dart';

class AllBookingsScreen extends StatefulWidget {
  @override
  _AllBookingsScreenState createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  String? _selectedFilter = 'All';
  DateTime? _selectedDate;

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
          'All Bookings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              setState(() {}); // Refresh the stream
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Filter by:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          underline: SizedBox(),
                          items: [
                            'All',
                            'Today',
                            'This Week',
                            'This Month',
                            'Pending',
                            'Completed',
                            'Cancelled',
                          ].map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedFilter == 'Today' && _selectedDate != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Selected Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                        child: Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Bookings List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredBookings(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error loading bookings'),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_online,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No bookings found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var bookingDoc = snapshot.data!.docs[index];
                    var bookingData = bookingDoc.data() as Map<String, dynamic>;
                    
                    return FutureBuilder(
                      future: _getUserDetails(bookingData),
                      builder: (context, AsyncSnapshot<Map<String, String>> userSnapshot) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with status
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(bookingData['paymentStatus']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getStatusIcon(bookingData['paymentStatus']),
                                            size: 12,
                                            color: _getStatusColor(bookingData['paymentStatus']),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            bookingData['paymentStatus']?.toString().toUpperCase() ?? 'PENDING',
                                            style: TextStyle(
                                              color: _getStatusColor(bookingData['paymentStatus']),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      'ID: ${bookingDoc.id.substring(0, 8)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                
                                // User info
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: Text(
                                        userSnapshot.hasData 
                                            ? _getInitials(userSnapshot.data!['name'] ?? 'U')
                                            : 'U',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userSnapshot.hasData 
                                                ? userSnapshot.data!['name'] ?? 'Unknown'
                                                : 'Loading...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            userSnapshot.hasData 
                                                ? userSnapshot.data!['email'] ?? ''
                                                : '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Divider(),
                                SizedBox(height: 8),
                                
                                // Trip details
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'From',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            bookingData['fromLocation'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            bookingData['departureTime'] ?? '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'To',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            bookingData['toLocation'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                          Text(
                                            bookingData['arrivalTime'] ?? '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                
                                // Seats and amount - CHANGED to BD
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Seats
                                    Wrap(
                                      spacing: 4,
                                      children: (bookingData['seats'] as List? ?? []).map((seat) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
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
                                      }).toList(),
                                    ),
                                    // Amount - CHANGED: $ to BD
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'BD ${bookingData['amount'] ?? bookingData['totalAmount'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                
                                // Booking date
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      'Booked: ${_formatDate(bookingData['bookingDate'])}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                
                                // View ticket button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TicketScreen(
                                            bookingId: bookingDoc.id,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.confirmation_number, size: 14),
                                    label: Text('View Ticket'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredBookings() {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('bookingDate', descending: true);

    // Apply filters
    if (_selectedFilter == 'Today') {
      DateTime now = DateTime.now();
      String todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      query = query.where('travelDate', isEqualTo: todayStr);
    } else if (_selectedFilter == 'Pending') {
      query = query.where('paymentStatus', isEqualTo: 'pending');
    } else if (_selectedFilter == 'Completed') {
      query = query.where('paymentStatus', isEqualTo: 'completed');
    } else if (_selectedFilter == 'Cancelled') {
      query = query.where('bookingStatus', isEqualTo: 'cancelled');
    }

    return query.snapshots();
  }

  Future<Map<String, String>> _getUserDetails(Map<String, dynamic> bookingData) async {
    try {
      if (bookingData['userId'] != null) {
        DocumentReference userRef = bookingData['userId'] as DocumentReference;
        DocumentSnapshot userDoc = await userRef.get();
        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          return {
            'name': userData['fullName'] ?? 'Unknown',
            'email': userData['email'] ?? '',
          };
        }
      }
    } catch (e) {
      print('Error getting user details: $e');
    }
    return {'name': 'Unknown', 'email': ''};
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    if (date is Timestamp) {
      DateTime dt = date.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    return date.toString();
  }
}