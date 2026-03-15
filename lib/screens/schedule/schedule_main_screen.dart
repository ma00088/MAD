import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import 'route_detail_screen.dart';
import 'schedule_timeline_screen.dart';

class ScheduleMainScreen extends StatefulWidget {
  @override
  _ScheduleMainScreenState createState() => _ScheduleMainScreenState();
}

class _ScheduleMainScreenState extends State<ScheduleMainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All Routes';

  final List<String> _filters = ['All Routes', 'Popular', 'Nearest'];

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
          'Bus Schedules',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.timeline, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleTimelineScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a route...',
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(height: 12),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.1),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Routes List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('routes')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error loading routes'),
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

                var routes = snapshot.data!.docs;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  routes = routes.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String routeName = data['routeName']?.toString().toLowerCase() ?? '';
                    String source = data['source']?.toString().toLowerCase() ?? '';
                    String destination = data['destination']?.toString().toLowerCase() ?? '';
                    
                    return routeName.contains(_searchQuery) ||
                        source.contains(_searchQuery) ||
                        destination.contains(_searchQuery);
                  }).toList();
                }

                if (routes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.route,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No routes found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your search',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    var routeDoc = routes[index];
                    var routeData = routeDoc.data() as Map<String, dynamic>;
                    
                    return FutureBuilder<int>(
                      future: _getTripCountForRoute(routeDoc.id),
                      builder: (context, tripCountSnapshot) {
                        return FutureBuilder<int>(
                          future: _getTotalBookingsForRoute(routeDoc.id),
                          builder: (context, bookingCountSnapshot) {
                            int tripCount = tripCountSnapshot.data ?? 0;
                            int bookingCount = bookingCountSnapshot.data ?? 0;
                            
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RouteDetailScreen(
                                      routeId: routeDoc.id,
                                      routeName: routeData['routeName'] ?? 'Unknown Route',
                                      source: routeData['source'] ?? '',
                                      destination: routeData['destination'] ?? '',
                                      distance: (routeData['distance'] ?? 0).toDouble(),
                                      duration: routeData['duration'] ?? 0,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 12),
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
                                child: Row(
                                  children: [
                                    // Route icon
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.route,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    
                                    // Route details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            routeData['routeName'] ?? 'Unknown Route',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '${routeData['source']} → ${routeData['destination']}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              // Trip count
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.schedule,
                                                      size: 12,
                                                      color: AppColors.primary,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '$tripCount trips',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              
                                              // Duration
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 12,
                                                      color: Colors.orange,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '${routeData['duration'] ?? 0} min',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.orange,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              if (bookingCount > 100) ...[
                                                SizedBox(width: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.trending_up,
                                                        size: 12,
                                                        color: Colors.green,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Popular',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.green,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Arrow
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getTripCountForRoute(String routeId) async {
    try {
      QuerySnapshot schedules = await FirebaseFirestore.instance
          .collection('schedules')
          .where('routeId', isEqualTo: FirebaseFirestore.instance.doc('routes/$routeId'))
          .where('isActive', isEqualTo: true)
          .get();
      return schedules.docs.length;
    } catch (e) {
      print('Error getting trip count: $e');
      return 0;
    }
  }

  Future<int> _getTotalBookingsForRoute(String routeId) async {
    try {
      // This is a simplified version - in real app, you'd aggregate bookings
      return 150; // Mock data
    } catch (e) {
      return 0;
    }
  }
}