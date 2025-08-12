import 'package:cloud_firestore/cloud_firestore.dart';

class TimeOffService {
  // Submit a new time off request directly (basic)
  static Future<void> submitTimeOffRequest({
    required String userId,
    required String organisationId,
    required DateTime weekStart,
    String? notes,
  }) async {
    final requestData = {
      'userId': userId,
      'organisationId': organisationId,
      'weekStart': Timestamp.fromDate(weekStart),
      'status': 'pending',
      'timestamp': Timestamp.now(),
      'notes': notes ?? '',
    };

    await FirebaseFirestore.instance
        .collection('timeOffRequests')
        .add(requestData);
  }

  // New method to handle auto-approval, rejection, waitlisting, and suggestions
  static Future<void> processTimeOffRequest({
    required String userId,
    required String organisationId,
    required DateTime weekStart,
    String? notes,
  }) async {
    final orgDoc = await FirebaseFirestore.instance
        .collection('organisations')
        .doc(organisationId)
        .get();

    if (!orgDoc.exists) {
      throw Exception('Organisation not found');
    }

    final orgData = orgDoc.data()!;
    final autoApprove = orgData['autoApproveTimeOff'] ?? false;
    final autoRejectIfUnstaffed = orgData['autoRejectIfUnstaffed'] ?? false;
    final enableWaitlist = orgData['enableWaitlist'] ?? false;
    final smartSuggestionEnabled = orgData['smartSuggestionEnabled'] ?? false;
    final staffingMinPerShift = orgData['staffingMinPerShift'] ?? 1;

    // Check current staffing for the weekStart requested
    final int currentStaffCount = await _countStaffOffForWeek(
      organisationId,
      weekStart,
    );

    // Decide status
    String status = 'pending';

    if (autoApprove) {
      // Auto approve if staffing min not exceeded
      if (currentStaffCount < staffingMinPerShift) {
        status = 'approved';
      } else if (autoRejectIfUnstaffed) {
        status = 'rejected';
      } else if (enableWaitlist) {
        status = 'waitlisted';
      } else {
        status = 'pending';
      }
    }

    // TODO: Implement smart suggestion logic if status is rejected or waitlisted and smartSuggestionEnabled = true

    final requestData = {
      'userId': userId,
      'organisationId': organisationId,
      'weekStart': Timestamp.fromDate(weekStart),
      'status': status,
      'timestamp': Timestamp.now(),
      'notes': notes ?? '',
    };

    await FirebaseFirestore.instance
        .collection('timeOffRequests')
        .add(requestData);
  }

  // Helper to count how many staff already off for that week
  static Future<int> _countStaffOffForWeek(
    String organisationId,
    DateTime weekStart,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('timeOffRequests')
        .where('organisationId', isEqualTo: organisationId)
        .where('weekStart', isEqualTo: Timestamp.fromDate(weekStart))
        .where('status', whereIn: ['approved', 'pending', 'waitlisted'])
        .get();

    // You can filter more based on your staffing rules here if needed
    return snapshot.docs.length;
  }

  // ... existing methods like getRequestsForOrganisation, approveRequest, rejectRequest remain unchanged
}
