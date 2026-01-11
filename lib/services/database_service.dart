import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/app_pref.dart';
import 'package:intl/intl.dart';
import '../models/reading_record.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'area';
  late final String _collection;

  DatabaseService() {
    _collection = 'daily_read${AppPref.appPref.getArea()}';
  }

  Future<void> ensurePastRecords(String uid, DateTime createdAt) async {
    final docRef = _firestore.collection(_collection).doc(uid);
    final doc = await docRef.get();

    List<dynamic> currentReadings = [];
    if (doc.exists) {
      currentReadings = doc.data()?['date'] ?? [];
    }

    // Create a Set of existing dates for O(1) lookup
    final existingDates = <String>{};
    for (var r in currentReadings) {
      existingDates.add(r['date']);
    }

    List<Map<String, dynamic>> newRecords = [];
    DateTime iterator = createdAt;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Normalize iterator to start of day
    iterator = DateTime(iterator.year, iterator.month, iterator.day);

    while (iterator.isBefore(today) || iterator.isAtSameMomentAs(today)) {
      final dateString = DateFormat('dd-MM-yyyy').format(iterator);

      if (!existingDates.contains(dateString)) {
        final record = ReadingRecord(date: dateString, timestamp: DateTime.now(), swaminiVato: false, vachnamrut: false);
        newRecords.add(record.toMap());
        existingDates.add(dateString);
      }
      iterator = iterator.add(const Duration(days: 1));
    }

    if (newRecords.isNotEmpty) {
      if (!doc.exists) {
        await docRef.set({'date': newRecords});
      } else {
        currentReadings.addAll(newRecords);
        await docRef.update({'date': currentReadings});
      }
    }
  }

  Future<void> updateDailyRead(String uid, ReadingRecord record) async {
    final docRef = _firestore.collection(_collection).doc(uid);

    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'date': [record.toMap()],
      });
    } else {
      List<dynamic> currentReadings = doc.data()?['date'] ?? [];

      int existingIndex = -1;
      for (int i = 0; i < currentReadings.length; i++) {
        if (currentReadings[i]['date'] == record.date) {
          existingIndex = i;
          break;
        }
      }

      if (existingIndex != -1) {
        currentReadings[existingIndex] = record.toMap();
      } else {
        currentReadings.add(record.toMap());
      }

      await docRef.update({'date': currentReadings});
    }
  }

  Future<ReadingRecord?> getUserReadingFromDate(String uid, DateTime date) async {
    final dateString = DateFormat('dd-MM-yyyy').format(date);

    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> readings = doc.data()!['date'] ?? [];

        for (var r in readings) {
          if (r['date'] == dateString) {
            return ReadingRecord.fromMap(r);
          }
        }
      }
    } catch (e) {
      print('Error fetching reading: $e');
    }
    return null;
  }

  Future<List<ReadingRecord>> getUserReadingsForPeriod(String uid, DateTime start, DateTime end) async {
    List<ReadingRecord> results = [];
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> readings = doc.data()!['date'] ?? [];

        for (var r in readings) {
          final record = ReadingRecord.fromMap(r);
          try {
            final parts = record.date.split('-');
            if (parts.length == 3) {
              final recordDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
              if (recordDate.isAfter(start.subtract(const Duration(days: 1))) && recordDate.isBefore(end.add(const Duration(days: 1)))) {
                results.add(record);
              }
            }
          } catch (e) {}
        }
      }
    } catch (e) {
      print('Error fetching reading range: $e');
    }
    results.sort((a, b) {
      try {
        final partsA = a.date.split('-');
        final dateA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
        final partsB = b.date.split('-');
        final dateB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    return results;
  }

  Future<List<Map<String, dynamic>>> getAllUserReadings(DateTime date) async {
    final dateString = DateFormat('dd-MM-yyyy').format(date);
    List<Map<String, dynamic>> results = [];

    try {
      final userSnapshot = await _firestore.collection(_usersCollection).get();

      for (var userDoc in userSnapshot.docs) {
        UserModel user = UserModel.fromMap(userDoc.data());

        final readingDoc = await _firestore.collection('daily_read${user.area}').doc(user.userId).get();
        bool swaminiVato = false;
        bool vachnamrut = false;
        bool hasEntry = false;
        String time = '';

        if (readingDoc.exists && readingDoc.data() != null) {
          List<dynamic> readings = readingDoc.data()!['date'] ?? [];
          for (var r in readings) {
            if (r['date'] == dateString) {
              swaminiVato = r['swaminiVato'] ?? false;
              vachnamrut = r['vachnamrut'] ?? false;
              hasEntry = true;

              if (r['timestamp'] != null) {
                try {
                  DateTime ts;
                  if (r['timestamp'] is Timestamp) {
                    ts = (r['timestamp'] as Timestamp).toDate();
                  } else if (r['timestamp'] is String) {
                    ts = DateTime.parse(r['timestamp']);
                  } else {
                    ts = DateTime.now();
                  }
                  time = DateFormat('hh:mm a').format(ts);
                } catch (e) {
                  print("Error parsing time: $e");
                }
              }
              break;
            }
          }
        }

        results.add({'user': user, 'swaminiVato': swaminiVato, 'vachnamrut': vachnamrut, 'hasEntry': hasEntry, 'time': time});
      }
    } catch (e) {
      print('Error fetching all readings: $e');
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> getAllUserReadingsForPeriod(DateTime start, DateTime end) async {
    List<Map<String, dynamic>> results = [];

    try {
      final userSnapshot = await _firestore.collection(_usersCollection).get();

      for (var userDoc in userSnapshot.docs) {
        UserModel user = UserModel.fromMap(userDoc.data());

        final readingDoc = await _firestore.collection('daily_read${user.area}').doc(user.userId).get();
        int swaminiCount = 0;
        int vachnamrutCount = 0;
        int totalDaysRead = 0;

        if (readingDoc.exists && readingDoc.data() != null) {
          List<dynamic> readings = readingDoc.data()!['date'] ?? [];
          for (var r in readings) {
            final record = ReadingRecord.fromMap(r);
            try {
              final parts = record.date.split('-');
              if (parts.length == 3) {
                final recordDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                if (recordDate.isAfter(start.subtract(const Duration(days: 1))) && recordDate.isBefore(end.add(const Duration(days: 1)))) {
                  if (record.swaminiVato) swaminiCount++;
                  if (record.vachnamrut) vachnamrutCount++;
                  if (record.swaminiVato || record.vachnamrut) totalDaysRead++;
                }
              }
            } catch (e) {}
          }
        }

        results.add({'user': user, 'swaminiCount': swaminiCount, 'vachnamrutCount': vachnamrutCount, 'totalDaysRead': totalDaysRead});
      }
    } catch (e) {
      print('Error fetching all readings for period: $e');
    }

    results.sort((a, b) => (b['totalDaysRead'] as int).compareTo(a['totalDaysRead'] as int));

    return results;
  }

  Future<Map<String, int>> getAdminStats() async {
    int totalEmployees = 0;
    int todayReadCount = 0;
    final todayString = DateFormat('dd-MM-yyyy').format(DateTime.now());

    try {
      final userSnapshot = await _firestore.collection(_usersCollection).get();
      totalEmployees = userSnapshot.docs.length;

      for (var userDoc in userSnapshot.docs) {
        UserModel user = UserModel.fromMap(userDoc.data());
        final readingDoc = await _firestore.collection('daily_read${user.area}').doc(user.userId).get();

        if (readingDoc.exists && readingDoc.data() != null) {
          List<dynamic> readings = readingDoc.data()!['date'] ?? [];
          for (var r in readings) {
            if (r['date'] == todayString) {
              if ((r['swaminiVato'] == true) || (r['vachnamrut'] == true)) {
                todayReadCount++;
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error getting stats: $e');
    }

    return {'totalEmployees': totalEmployees, 'todayReadCount': todayReadCount};
  }

  Future<List<UserModel>> getAllUsers() async {
    List<UserModel> users = [];
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      users = snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching users: $e');
    }
    return users;
  }

  Future<List<Map<String, dynamic>>> getAllUserDailyReadings(DateTime start, DateTime end) async {
    List<Map<String, dynamic>> results = [];

    try {
      final userSnapshot = await _firestore.collection(_usersCollection).get();

      for (var userDoc in userSnapshot.docs) {
        UserModel user = UserModel.fromMap(userDoc.data());

        final readingDoc = await _firestore.collection('daily_read${user.area}').doc(user.userId).get();
        Map<String, ReadingRecord> dailyReadings = {};

        if (readingDoc.exists && readingDoc.data() != null) {
          List<dynamic> readings = readingDoc.data()!['date'] ?? [];
          for (var r in readings) {
            final record = ReadingRecord.fromMap(r);
            try {
              final parts = record.date.split('-');
              if (parts.length == 3) {
                final recordDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                // Normalize dates for comparison
                final normStart = DateTime(start.year, start.month, start.day);
                final normEnd = DateTime(end.year, end.month, end.day);
                final normRecord = DateTime(recordDate.year, recordDate.month, recordDate.day);

                if ((normRecord.isAfter(normStart) || normRecord.isAtSameMomentAs(normStart)) &&
                    (normRecord.isBefore(normEnd) || normRecord.isAtSameMomentAs(normEnd))) {
                  dailyReadings[record.date] = record;
                }
              }
            } catch (e) {
              print('Date parsing error: $e');
            }
          }
        }

        results.add({'user': user, 'readings': dailyReadings});
      }
    } catch (e) {
      print('Error fetching daily readings: $e');
    }

    // Sort by name
    results.sort((a, b) => (a['user'] as UserModel).name.compareTo((b['user'] as UserModel).name));

    return results;
  }
}
