import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'invite_code_page.dart';
import 'email_invite_page.dart';
import 'invite_management_page.dart';
import 'organisation_list.dart';
import 'package:shift_cover/services/user_service.dart';

class ManagerHomePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const ManagerHomePage({
    required this.userData,
    required this.userId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? orgIds =
        (userData['organisationIds'] as List<dynamic>?);
    final organisationId = (orgIds != null && orgIds.isNotEmpty)
        ? orgIds.first.toString()
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create-organisation');
                    },
                    child: const Text('Create Organisation'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: organisationId.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InviteCodePage(
                                  organisationId: organisationId,
                                ),
                              ),
                            );
                          },
                    child: const Text('Generate Invite Code'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: organisationId.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmailInvitePage(
                                  organisationId: organisationId,
                                  invitedBy: userId,
                                ),
                              ),
                            );
                          },
                    child: const Text('Send Email Invite'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: organisationId.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InviteManagementPage(
                                  organisationId: organisationId,
                                ),
                              ),
                            );
                          },
                    child: const Text('Manage Invites'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Expanded(child: OrganisationList()),
        ],
      ),
    );
  }
}
