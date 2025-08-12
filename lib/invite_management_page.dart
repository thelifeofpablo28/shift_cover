import 'package:flutter/material.dart';

class InviteManagementPage extends StatefulWidget {
  final String organisationId;

  const InviteManagementPage({Key? key, required this.organisationId})
    : super(key: key);

  @override
  _InviteManagementPageState createState() => _InviteManagementPageState();
}

class _InviteManagementPageState extends State<InviteManagementPage> {
  // Dummy data to simulate invites
  List<Map<String, String>> invites = [
    {'email': 'user1@example.com', 'status': 'Pending'},
    {'email': 'user2@example.com', 'status': 'Accepted'},
  ];

  void _revokeInvite(int index) {
    setState(() {
      invites.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invite revoked')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Invites for ${widget.organisationId}'),
      ),
      body: invites.isEmpty
          ? Center(child: Text('No outstanding invites'))
          : ListView.builder(
              itemCount: invites.length,
              itemBuilder: (context, index) {
                final invite = invites[index];
                return ListTile(
                  title: Text(invite['email']!),
                  subtitle: Text('Status: ${invite['status']}'),
                  trailing: invite['status'] == 'Pending'
                      ? IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _revokeInvite(index),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
