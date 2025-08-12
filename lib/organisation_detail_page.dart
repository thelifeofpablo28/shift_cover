import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shift_cover/organisation_services_page.dart';

class OrganisationDetailPage extends StatelessWidget {
  final String orgId;

  const OrganisationDetailPage({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    final orgDocRef = FirebaseFirestore.instance
        .collection('organisations')
        .doc(orgId);

    return Scaffold(
      appBar: AppBar(title: const Text('Organisation Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: orgDocRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Organisation not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'Unnamed Organisation';
          final managers = List<String>.from(data['managers'] ?? []);
          final employees = List<String>.from(data['employees'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(
                  'Name: $name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Managers:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                managers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No managers added yet.'),
                      )
                    : Column(
                        children: managers
                            .map((uid) => UserDisplayTile(userId: uid))
                            .toList(),
                      ),
                const SizedBox(height: 16),
                Text(
                  'Employees:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                employees.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No employees added yet.'),
                      )
                    : Column(
                        children: employees
                            .map((uid) => UserDisplayTile(userId: uid))
                            .toList(),
                      ),
                // Future: Add buttons or editing controls here
              ],
            ),
          );
        },
      ),
    );
  }
}

class UserDisplayTile extends StatelessWidget {
  final String userId;

  const UserDisplayTile({super.key, required this.userId});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircularProgressIndicator(strokeWidth: 2),
            title: Text('Loading user...'),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return ListTile(title: Text('User not found: $userId'));
        }

        final userData = snapshot.data!;
        final displayName =
            userData['displayName'] ?? userData['email'] ?? userId;

        return ListTile(
          title: Text(displayName),
          // Future: Add trailing edit buttons here if needed
        );
      },
    );
  }
}
