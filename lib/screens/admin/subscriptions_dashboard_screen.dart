import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import 'subscription_details_screen.dart';

class SubscriptionsDashboardScreen extends StatefulWidget {
  @override
  _SubscriptionsDashboardScreenState createState() => _SubscriptionsDashboardScreenState();
}

class _SubscriptionsDashboardScreenState extends State<SubscriptionsDashboardScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Stats
  int _totalActive = 0;
  int _expiringSoon = 0;
  double _totalRevenue = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Get all active subscriptions
      QuerySnapshot activeSnapshot = await FirebaseFirestore.instance
          .collection('student_memberships')
          .where('status', isEqualTo: 'active')
          .get();
      
      _totalActive = activeSnapshot.docs.length;
      
      // Calculate revenue
      double revenue = 0;
      for (var doc in activeSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        revenue += (data['price'] ?? 0).toDouble();
      }
      _totalRevenue = revenue;
      
      // Count expiring soon (within 7 days)
      DateTime sevenDaysFromNow = DateTime.now().add(Duration(days: 7));
      int expiring = 0;
      for (var doc in activeSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['endDate'] != null) {
          Timestamp endDate = data['endDate'];
          if (endDate.toDate().isBefore(sevenDaysFromNow)) {
            expiring++;
          }
        }
      }
      _expiringSoon = expiring;
      
    } catch (e) {
      print('Error loading stats: $e');
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  // Helper method to get user details
  Future<DocumentSnapshot> _getUserDetails(dynamic userId) async {
    if (userId == null) return Future.value(null);
    
    // Handle if userId is a DocumentReference
    if (userId is DocumentReference) {
      return userId.get();
    }
    // Handle if userId is a String
    return FirebaseFirestore.instance.collection('users').doc(userId.toString()).get();
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
          'Subscriptions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          if (!_isLoadingStats)
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people,
                      value: '$_totalActive',
                      label: 'Active',
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.warning,
                      value: '$_expiringSoon',
                      label: 'Expiring Soon',
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.attach_money,
                      value: 'BD ${_totalRevenue.toStringAsFixed(2)}',
                      label: 'Revenue',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          
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
                      hintText: 'Search by student name or ID...',
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
                    children: [
                      _buildFilterChip('All', 'All'),
                      _buildFilterChip('Active', 'active'),
                      _buildFilterChip('Expiring Soon', 'expiring'),
                      _buildFilterChip('Cancelled', 'cancelled'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Subscriptions List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('student_memberships')
                  .orderBy('endDate', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading subscriptions'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                var subscriptions = snapshot.data!.docs;
                
                // Apply filters
                var filteredSubs = subscriptions.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  
                  // Status filter
                  if (_selectedFilter != 'All') {
                    if (_selectedFilter == 'expiring') {
                      // Check if expiring within 7 days
                      if (data['endDate'] != null) {
                        Timestamp endDate = data['endDate'];
                        DateTime expiry = endDate.toDate();
                        DateTime sevenDaysFromNow = DateTime.now().add(Duration(days: 7));
                        if (expiry.isAfter(sevenDaysFromNow)) {
                          return false;
                        }
                      } else {
                        return false;
                      }
                    } else if (data['status'] != _selectedFilter) {
                      return false;
                    }
                  }
                  
                  // Search filter - will be applied after fetching user details
                  // We'll handle search in the builder
                  return true;
                }).toList();
                
                if (filteredSubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_membership, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No subscriptions found',
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
                  itemCount: filteredSubs.length,
                  itemBuilder: (context, index) {
                    var subDoc = filteredSubs[index];
                    var subData = subDoc.data() as Map<String, dynamic>;
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: _getUserDetails(subData['studentId']),
                      builder: (context, userSnapshot) {
                        String studentName = 'Loading...';
                        String studentInitials = '??';
                        
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          studentName = userData['fullName'] ?? 'Unknown';
                          
                          List<String> names = studentName.split(' ');
                          if (names.length > 1) {
                            studentInitials = '${names[0][0]}${names[1][0]}'.toUpperCase();
                          } else {
                            studentInitials = studentName[0].toUpperCase();
                          }
                        }
                        
                        // Apply search filter
                        if (_searchQuery.isNotEmpty) {
                          if (!studentName.toLowerCase().contains(_searchQuery)) {
                            return SizedBox.shrink();
                          }
                        }
                        
                        DateTime expiryDate = (subData['endDate'] as Timestamp).toDate();
                        bool isExpiringSoon = expiryDate.difference(DateTime.now()).inDays <= 7;
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionDetailsScreen(
                                  subscriptionId: subDoc.id,
                                  subscriptionData: subData,
                                  studentName: studentName,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.green.withOpacity(0.1),
                                        child: Text(
                                          studentInitials,
                                          style: TextStyle(
                                            color: Colors.green,
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
                                              studentName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              subData['planName'] ?? 'Subscription',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isExpiringSoon
                                              ? Colors.orange.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                                          style: TextStyle(
                                            color: isExpiringSoon
                                                ? Colors.orange
                                                : Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Divider(),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'BD ${subData['price'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: subData['status'] == 'active'
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          subData['status']?.toString().toUpperCase() ?? 'ACTIVE',
                                          style: TextStyle(
                                            color: subData['status'] == 'active'
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
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

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withOpacity(0.1),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: _selectedFilter == value ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}