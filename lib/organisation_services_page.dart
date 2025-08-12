import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftRequirement {
  String? id;
  DateTime startTime;
  DateTime endTime;
  Map<String, int> minimums;

  ShiftRequirement({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.minimums,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'minimums': minimums,
    };
  }

  static ShiftRequirement fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftRequirement(
      id: doc.id,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      minimums: Map<String, int>.from(data['minimums']),
    );
  }
}

class OrganisationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addShiftRequirement(
    String orgId,
    ShiftRequirement shiftReq,
  ) async {
    final collectionRef = _firestore
        .collection('organisations')
        .doc(orgId)
        .collection('shiftRequirements');
    await collectionRef.add(shiftReq.toMap());
  }

  Future<void> updateShiftRequirement(
    String orgId,
    ShiftRequirement shiftReq,
  ) async {
    if (shiftReq.id == null) throw Exception('ShiftRequirement id is null');
    final docRef = _firestore
        .collection('organisations')
        .doc(orgId)
        .collection('shiftRequirements')
        .doc(shiftReq.id);
    await docRef.set(shiftReq.toMap());
  }

  Future<void> deleteShiftRequirement(String orgId, String shiftReqId) async {
    final docRef = _firestore
        .collection('organisations')
        .doc(orgId)
        .collection('shiftRequirements')
        .doc(shiftReqId);
    await docRef.delete();
  }

  Stream<List<ShiftRequirement>> getShiftRequirements(String orgId) {
    final collectionRef = _firestore
        .collection('organisations')
        .doc(orgId)
        .collection('shiftRequirements');
    return collectionRef.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ShiftRequirement.fromDoc(doc)).toList(),
    );
  }
}
