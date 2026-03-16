import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== USER AUTHENTICATION ==========
  
  // Sign in with email/password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Login failed: ${e.message}');
      return null;
    }
  }

  // Sign up new student
  Future<User?> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    required String department,
  }) async {
    try {
      // Create auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Save additional user data to Firestore
      await _db.collection('users').doc(result.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'studentId': studentId,
        'department': department,
        'role': 'student',
        'hasSubscription': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return result.user;
    } catch (e) {
      print('Registration failed: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ========== BUS SCHEDULES ==========
  
  // Get all available buses for a route (Stream for real-time updates)
  Stream<QuerySnapshot> getBusesByRoute(String source, String destination) {
    return _db
        .collection('schedules')
        .where('source', isEqualTo: source)
        .where('destination', isEqualTo: destination)
        .snapshots();
  }

  // Get schedules by route (Future for one-time fetch)
  Future<QuerySnapshot> getSchedulesByRoute(String source, String destination) async {
    try {
      print('🔍 FIRESTORE: Getting schedules for route $source → $destination');
      
      // First find the route
      QuerySnapshot routeSnapshot = await _db
          .collection('routes')
          .where('source', isEqualTo: source)
          .where('destination', isEqualTo: destination)
          .limit(1)
          .get();
      
      if (routeSnapshot.docs.isEmpty) {
        print('❌ FIRESTORE: No route found for $source to $destination');
        return await _db.collection('empty').limit(0).get();
      }
      
      String routeId = routeSnapshot.docs.first.id;
      print('✅ FIRESTORE: Found route ID: $routeId');
      
      // Then get schedules for that route
      QuerySnapshot schedules = await _db
          .collection('schedules')
          .where('routeId', isEqualTo: _db.doc('routes/$routeId'))
          .where('isActive', isEqualTo: true)
          .get();
      
      print('✅ FIRESTORE: Found ${schedules.docs.length} schedules for route');
      
      // Log each schedule for debugging
      for (var doc in schedules.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('   📅 Schedule: ${data['departureTime']} → ${data['arrivalTime']}, Days: ${data['operatingDays']}, Active: ${data['isActive']}');
      }
      
      return schedules;
    } catch (e) {
      print('❌ FIRESTORE Error getting schedules: $e');
      return await _db.collection('empty').limit(0).get();
    }
  }
  
  // Get schedules by route, time and date
  Future<QuerySnapshot> getSchedulesByRouteAndTime(
    String source, 
    String destination, 
    String time,
    DateTime date
  ) async {
    try {
      // Get day of week (e.g., "Mon", "Tue")
      List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      String dayAbbrev = days[date.weekday % 7];
      
      print('🔍 FIRESTORE: Searching for: $source → $destination');
      print('   Time: $time');
      print('   Date: ${date.year}-${date.month}-${date.day}');
      print('   Day of week: $dayAbbrev (${date.weekday})');
      
      // First find the route
      QuerySnapshot routeSnapshot = await _db
          .collection('routes')
          .where('source', isEqualTo: source)
          .where('destination', isEqualTo: destination)
          .limit(1)
          .get();
      
      if (routeSnapshot.docs.isEmpty) {
        print('❌ FIRESTORE: No route found for $source to $destination');
        return await _db.collection('empty').limit(0).get();
      }
      
      String routeId = routeSnapshot.docs.first.id;
      print('✅ FIRESTORE: Found route ID: $routeId');
      
      // First, get ALL schedules for this route to see what's available
      QuerySnapshot allSchedules = await _db
          .collection('schedules')
          .where('routeId', isEqualTo: _db.doc('routes/$routeId'))
          .where('isActive', isEqualTo: true)
          .get();
      
      print('📊 FIRESTORE: Total active schedules for this route: ${allSchedules.docs.length}');
      
      for (var doc in allSchedules.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print('   Available: ${data['departureTime']} - Days: ${data['operatingDays']}');
      }
      
      // Now get schedules that match time and day
      QuerySnapshot schedules = await _db
          .collection('schedules')
          .where('routeId', isEqualTo: _db.doc('routes/$routeId'))
          .where('departureTime', isEqualTo: time)
          .where('operatingDays', arrayContains: dayAbbrev)
          .where('isActive', isEqualTo: true)
          .get();
      
      print('✅ FIRESTORE: Found ${schedules.docs.length} matching schedules');
      
      if (schedules.docs.isEmpty) {
        print('⚠️ FIRESTORE: No schedules match the criteria:');
        print('   Route ID: $routeId');
        print('   Time: $time');
        print('   Day: $dayAbbrev');
      } else {
        for (var doc in schedules.docs) {
          var data = doc.data() as Map<String, dynamic>;
          print('   ✅ Match: ${data['departureTime']} - Days: ${data['operatingDays']}');
        }
      }
      
      return schedules;
    } catch (e) {
      print('❌ FIRESTORE Error in getSchedulesByRouteAndTime: $e');
      return await _db.collection('empty').limit(0).get();
    }
  }

  // Get all schedules (for admin)
  Stream<QuerySnapshot> getAllSchedules() {
    return _db.collection('schedules').snapshots();
  }

  // ========== BUSES ==========
  
  // Get bus by ID
  Future<DocumentSnapshot> getBus(String busId) async {
    return await _db.collection('buses').doc(busId).get();
  }

  // ========== ROUTES ==========
  
  // Get all routes
  Future<QuerySnapshot> getAllRoutes() async {
    return await _db.collection('routes').get();
  }

  // Get route by ID
  Future<DocumentSnapshot> getRoute(String routeId) async {
    return await _db.collection('routes').doc(routeId).get();
  }

  // ========== BOOKINGS ==========
  
  // Create a new booking
  Future<String> createBooking({
    required String userId,
    required String scheduleId,
    required List<int> seats,
    required double amount,
    String? promoCode,
  }) async {
    try {
      // Generate booking number
      String bookingNumber = 'UTB${DateTime.now().millisecondsSinceEpoch}';
      
      // Get schedule details
      DocumentSnapshot scheduleDoc = await _db.collection('schedules').doc(scheduleId).get();
      
      if (!scheduleDoc.exists) {
        throw Exception('Schedule not found');
      }
      
      Map<String, dynamic> scheduleData = scheduleDoc.data() as Map<String, dynamic>;
      
      // Get bus details
      String busName = 'UTB Bus';
      String busNumber = '';
      
      if (scheduleData['busId'] != null && scheduleData['busId'] is DocumentReference) {
        DocumentReference busRef = scheduleData['busId'] as DocumentReference;
        DocumentSnapshot busDoc = await busRef.get();
        if (busDoc.exists) {
          Map<String, dynamic> busData = busDoc.data() as Map<String, dynamic>;
          busName = busData['busName'] ?? 'UTB Bus';
          busNumber = busData['busNumber'] ?? '';
        }
      }
      
      // Get route details
      String fromLocation = '';
      String toLocation = '';
      
      if (scheduleData['routeId'] != null && scheduleData['routeId'] is DocumentReference) {
        DocumentReference routeRef = scheduleData['routeId'] as DocumentReference;
        DocumentSnapshot routeDoc = await routeRef.get();
        if (routeDoc.exists) {
          Map<String, dynamic> routeData = routeDoc.data() as Map<String, dynamic>;
          fromLocation = routeData['source'] ?? '';
          toLocation = routeData['destination'] ?? '';
        }
      }
      
      // Format travel date as string for easier querying
      String travelDateStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      
      // Create booking document
      DocumentReference bookingRef = await _db.collection('bookings').add({
        'userId': _db.collection('users').doc(userId),
        'scheduleId': _db.collection('schedules').doc(scheduleId),
        'bookingNumber': bookingNumber,
        'seats': seats,
        'passengers': seats.length,
        'amount': amount,
        'promoCode': promoCode,
        'paymentStatus': 'pending',
        'bookingStatus': 'confirmed',
        'bookingDate': FieldValue.serverTimestamp(),
        'travelDate': travelDateStr,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'departureTime': scheduleData['departureTime'] ?? '',
        'arrivalTime': scheduleData['arrivalTime'] ?? '',
        'companyName': busName,
        'busNumber': busNumber,
        'qrCode': 'QR$bookingNumber',
      });
      
      print('✅ FIRESTORE: Booking created with ID: ${bookingRef.id}');
      return bookingRef.id;
    } catch (e) {
      print('❌ FIRESTORE Error creating booking: $e');
      throw e;
    }
  }

  // Update available seats
  Future<void> updateAvailableSeats(String scheduleId, int seatsBooked) async {
    try {
      DocumentReference scheduleRef = _db.collection('schedules').doc(scheduleId);
      
      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(scheduleRef);
        if (snapshot.exists) {
          int currentSeats = snapshot.get('availableSeats') ?? snapshot.get('totalSeats') ?? 40;
          int newSeats = currentSeats - seatsBooked;
          // Ensure we don't go below 0
          if (newSeats < 0) newSeats = 0;
          transaction.update(scheduleRef, {'availableSeats': newSeats});
          print('✅ FIRESTORE: Updated seats for schedule $scheduleId: $currentSeats → $newSeats');
        }
      });
    } catch (e) {
      print('❌ FIRESTORE Error updating seats: $e');
      throw e;
    }
  }

  // Get user's bookings (Future for one-time fetch)
  Future<QuerySnapshot> getUserBookings(String userId) async {
    try {
      print('🔍 FIRESTORE: Getting bookings for user $userId');
      
      QuerySnapshot bookings = await _db
          .collection('bookings')
          .where('userId', isEqualTo: _db.collection('users').doc(userId))
          .orderBy('bookingDate', descending: true)
          .get();
      
      print('✅ FIRESTORE: Found ${bookings.docs.length} bookings');
      return bookings;
    } catch (e) {
      print('❌ FIRESTORE Error getting user bookings: $e');
      return await _db.collection('empty').limit(0).get();
    }
  }

  // Stream user's bookings (real-time updates)
  Stream<QuerySnapshot> streamUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: _db.collection('users').doc(userId))
        .orderBy('bookingDate', descending: true)
        .snapshots();
  }

  // Get booking by ID
  Future<DocumentSnapshot> getBooking(String bookingId) async {
    try {
      return await _db.collection('bookings').doc(bookingId).get();
    } catch (e) {
      print('❌ FIRESTORE Error getting booking: $e');
      rethrow;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String bookingId, String status) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'paymentStatus': status,
        if (status == 'completed') 'paymentDate': FieldValue.serverTimestamp(),
      });
      print('✅ FIRESTORE: Updated payment status for booking $bookingId to $status');
    } catch (e) {
      print('❌ FIRESTORE Error updating payment status: $e');
      rethrow;
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'bookingStatus': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      print('✅ FIRESTORE: Cancelled booking $bookingId');
    } catch (e) {
      print('❌ FIRESTORE Error cancelling booking: $e');
      rethrow;
    }
  }

  // ========== SUBSCRIPTIONS ==========
  
  // Create a new subscription
  Future<String> createSubscription({
    required String userId,
    required Map<String, dynamic> plan,
    required String paymentMethod,
    required String email,
    required String phone,
  }) async {
    try {
      DateTime now = DateTime.now();
      DateTime expiryDate = now.add(Duration(days: plan['duration']));
      
      // Get user details
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
      
      String studentName = userDoc.get('fullName') ?? 'Student';
      String studentId = userDoc.get('studentId') ?? '';
      
      // Parse price from string (e.g., "BD 15.00" -> 15.00)
      double price = 0.0;
      dynamic priceValue = plan['price'];
      
      if (priceValue is String) {
        // Remove 'BD ' and any commas, then parse
        String cleanPrice = priceValue.replaceAll('BD ', '').replaceAll(',', '');
        price = double.parse(cleanPrice);
      } else if (priceValue is num) {
        price = priceValue.toDouble();
      }
      
      // Create subscription record
      DocumentReference subRef = await _db.collection('student_memberships').add({
        'studentId': userId,
        'studentName': studentName,
        'studentIdNumber': studentId,
        'planName': plan['name'].toString().trim(),
        'planDetails': {
          'name': plan['name'],
          'price': plan['price'],
          'period': plan['period'],
          'duration': plan['duration'],
          'features': plan['features'],
        },
        'price': price,
        'durationDays': plan['duration'],
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(expiryDate),
        'status': 'active',
        'autoRenewal': true,
        'paymentMethod': paymentMethod,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ FIRESTORE: Subscription created with ID: ${subRef.id}');
      return subRef.id;
    } catch (e) {
      print('❌ FIRESTORE Error creating subscription: $e');
      throw e;
    }
  }

  // Get user's active subscription
  Future<DocumentSnapshot?> getUserActiveSubscription(String userId) async {
    try {
      QuerySnapshot subscriptions = await _db
          .collection('student_memberships')
          .where('studentId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('endDate', descending: false)
          .limit(1)
          .get();
      
      if (subscriptions.docs.isNotEmpty) {
        return subscriptions.docs.first;
      }
      return null;
    } catch (e) {
      print('❌ FIRESTORE Error getting user subscription: $e');
      return null;
    }
  }

  // Get all subscriptions (for admin)
  Stream<QuerySnapshot> getAllSubscriptions() {
    return _db
        .collection('student_memberships')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get active subscriptions count (for admin stats)
  Future<int> getActiveSubscriptionsCount() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('student_memberships')
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ FIRESTORE Error getting active subscriptions count: $e');
      return 0;
    }
  }

  // Get expiring soon subscriptions (within 7 days)
  Future<QuerySnapshot> getExpiringSubscriptions() async {
    try {
      DateTime sevenDaysFromNow = DateTime.now().add(Duration(days: 7));
      
      return await _db
          .collection('student_memberships')
          .where('status', isEqualTo: 'active')
          .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(sevenDaysFromNow))
          .orderBy('endDate')
          .get();
    } catch (e) {
      print('❌ FIRESTORE Error getting expiring subscriptions: $e');
      return await _db.collection('empty').limit(0).get();
    }
  }

  // Cancel subscription (FIXED - Now updates user document)
  Future<void> cancelSubscription(String subscriptionId, {String? reason}) async {
    try {
      // First get the subscription to find the student ID
      DocumentSnapshot subDoc = await _db.collection('student_memberships').doc(subscriptionId).get();
      
      if (!subDoc.exists) {
        throw Exception('Subscription not found');
      }
      
      Map<String, dynamic> subData = subDoc.data() as Map<String, dynamic>;
      String studentId = subData['studentId'];
      
      // Update subscription status
      await _db.collection('student_memberships').doc(subscriptionId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'cancelledBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user's hasSubscription flag
      await _db.collection('users').doc(studentId).update({
        'hasSubscription': false,
        'subscriptionCancelledAt': FieldValue.serverTimestamp(),
        'subscriptionCancelledBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ FIRESTORE: Subscription $subscriptionId cancelled. User $studentId updated.');
      
    } catch (e) {
      print('❌ FIRESTORE Error cancelling subscription: $e');
      throw e;
    }
  }

  // Renew subscription
  Future<void> renewSubscription(String subscriptionId) async {
    try {
      DocumentSnapshot subDoc = await _db.collection('student_memberships').doc(subscriptionId).get();
      if (!subDoc.exists) throw Exception('Subscription not found');
      
      Map<String, dynamic> subData = subDoc.data() as Map<String, dynamic>;
      int duration = subData['durationDays'] ?? 30;
      
      DateTime now = DateTime.now();
      DateTime newEndDate = now.add(Duration(days: duration));
      
      await _db.collection('student_memberships').doc(subscriptionId).update({
        'status': 'active',
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(newEndDate),
        'renewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user's subscription expiry
      String studentId = subData['studentId'];
      String formattedExpiry = "${_getMonthName(newEndDate.month)} ${newEndDate.day}, ${newEndDate.year}";
      
      await _db.collection('users').doc(studentId).update({
        'hasSubscription': true,
        'subscriptionExpiry': formattedExpiry,
        'lastRenewal': FieldValue.serverTimestamp(),
      });
      
      print('✅ FIRESTORE: Subscription $subscriptionId renewed');
    } catch (e) {
      print('❌ FIRESTORE Error renewing subscription: $e');
      throw e;
    }
  }

  // Helper method for month names
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}