import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'organisation_detail_page.dart';

class OrganisationList extends StatelessWidget {
  const OrganisationList({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }

    // Listen to organisations where current user is a manager
    final orgsQuery = FirebaseFirestore.instance
        .collection('organisations')
        .where('managers', arrayContains: user.uid);

    return StreamBuilder<QuerySnapshot>(
      stream: orgsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No organisations found.'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final org = docs[index];
            final orgName = org['name'] ?? 'Unnamed Organisation';
            final orgId = org.id;

            return ListTile(
              title: Text(orgName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                   builder: (context) => OrganisationDetailPage(orgId: orgId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}