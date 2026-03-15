import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../ticket_booking_screen.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  final String routeName;
  final String source;
  final String destination;
  final double distance;
  final int duration;

  const RouteDetailScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
    required this.source,
    required this.destination,
    required this.distance,
    required this.duration,
  }) : super(key: key);

  @override
  _RouteDetailScreenState createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  late DateTime _selectedDate;
  List<Map<String, dynamic>> _stops = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadStops();
  }

  Future<void> _loadStops() async {
    try {
      QuerySnapshot stopsSnapshot = await FirebaseFirestore.instance
          .collection('bus_stops')
          .where('routeId', isEqualTo: FirebaseFirestore.instance.doc('routes/${widget.routeId}'))
          .orderBy('stopOrder')
          .get();

      setState(() {
        _stops = stopsSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['stopName'] ?? 'Unknown Stop',
            'order': data['stopOrder'] ?? 0,
            'time': data['estimatedTimeFromStart'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading stops: $e');
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
          'Route Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Header
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.routeName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.source} → ${widget.destination}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          Icons.straighten,
                          '${widget.distance} km',
                          'Distance',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.access_time,
                          '${widget.duration} min',
                          'Duration',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.route,
                          '${_stops.length} stops',
                          'Total Stops',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date Selector
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Travel Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 90)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Today's Schedules
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Today's Departures",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('routeId', isEqualTo: FirebaseFirestore.instance.doc('routes/${widget.routeId}'))
                  .where('isActive', isEqualTo: true)
                  .orderBy('departureTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading schedules'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var schedules = snapshot.data!.docs;

                if (schedules.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No schedules available',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    var scheduleDoc = schedules[index];
                    var scheduleData = scheduleDoc.data() as Map<String, dynamic>;

                    return FutureBuilder<int>(
                      future: _getAvailableSeats(scheduleDoc.id, _selectedDate),
                      builder: (context, seatsSnapshot) {
                        int availableSeats = seatsSnapshot.data ?? 0;
                        bool isFullyBooked = availableSeats <= 0;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFullyBooked ? Colors.red.withOpacity(0.3) : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Time
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scheduleData['departureTime'] ?? '--:--',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      scheduleData['arrivalTime'] ?? '--:--',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Seats
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_seat,
                                      color: isFullyBooked ? Colors.red : Colors.green,
                                      size: 20,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      isFullyBooked ? 'Full' : '$availableSeats seats',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isFullyBooked ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Price and Book button
                              Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'BD ${scheduleData['price'] ?? 25}.00',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        if (!isFullyBooked)
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => TicketBookingScreen(
                                                    initialFrom: widget.source,
                                                    initialTo: widget.destination,
                                                    initialDate: _selectedDate,
                                                    initialTime: scheduleData['departureTime'],
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              minimumSize: Size(80, 30),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text('Book'),
                                          )
                                        else
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Full',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            // Bus Stops Section
            if (_stops.isNotEmpty) ...[
              SizedBox(height: 24),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Bus Stops',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 12),
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
                  children: List.generate(_stops.length, (index) {
                    var stop = _stops[index];
                    bool isLast = index == _stops.length - 1;
                    
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stop indicator
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: index == 0 ? Colors.green : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 30,
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                              ],
                            ),
                            SizedBox(width: 16),
                            
                            // Stop details
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      stop['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                        color: index == 0 ? Colors.green : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(stop['time']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isLast) SizedBox(height: 8),
                      ],
                    );
                  }),
                ),
              ),
            ],

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getAvailableSeats(String scheduleId, DateTime date) async {
    try {
      // Get bus total seats
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(scheduleId)
          .get();
      
      var scheduleData = scheduleDoc.data() as Map<String, dynamic>;
      
      // Get bus details
      int totalSeats = 40; // Default
      if (scheduleData['busId'] != null) {
        DocumentReference busRef = scheduleData['busId'] as DocumentReference;
        DocumentSnapshot busDoc = await busRef.get();
        if (busDoc.exists) {
          totalSeats = (busDoc.data() as Map<String, dynamic>)['totalSeats'] ?? 40;
        }
      }

      // Count booked seats for this date
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      QuerySnapshot bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('scheduleId', isEqualTo: FirebaseFirestore.instance.doc('schedules/$scheduleId'))
          .where('travelDate', isEqualTo: dateStr)
          .where('bookingStatus', isNotEqualTo: 'cancelled')
          .get();

      int bookedSeats = 0;
      for (var doc in bookings.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['seats'] != null && data['seats'] is List) {
          bookedSeats += (data['seats'] as List).length;
        }
      }

      return totalSeats - bookedSeats;
    } catch (e) {
      print('Error calculating available seats: $e');
      return 0;
    }
  }

  String _formatTime(int minutesFromStart) {
    if (minutesFromStart == 0) return 'Start';
    int hours = minutesFromStart ~/ 60;
    int minutes = minutesFromStart % 60;
    return '${hours}h ${minutes}m';
  }
}